#!/usr/bin/env node
// Execute a review-response plan: reply, vote and resolve across every thread at once.
// Usage: apply.ts PLAN.json   (PLAN of "-" reads stdin)

import { execFile } from 'node:child_process'
import { readFile } from 'node:fs/promises'
import { promisify } from 'node:util'

type Vote = 'THUMBS_UP' | 'THUMBS_DOWN'
type State = 'ok' | 'failed' | 'skipped' | 'duplicate'

interface PlanItem {
  ref: string
  threadId?: string
  prId?: string
  commentId?: string
  bodyFile?: string
  vote?: Vote
  resolve?: boolean
}

interface Result {
  ref: string
  reply: State
  replyUrl: string
  vote: State
  resolve: State
  err: string
}

const run = promisify(execFile)
const JOBS = Number(process.env.ADDRESS_REVIEW_JOBS) || 4

const die = (msg: string): never => {
  console.error(`apply.ts: ${msg}`)
  process.exit(2)
}

const Q = {
  comment: `mutation($subjectId:ID!, $body:String!) {
    addComment(input: {subjectId: $subjectId, body: $body}) { commentEdge { node { url } } }
  }`,
  vote: `mutation($subjectId:ID!, $content:ReactionContent!) {
    addReaction(input: {subjectId: $subjectId, content: $content}) { reaction { content } }
  }`,
  resolve: `mutation($threadId:ID!) {
    resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } }
  }`,
}

// No shell, so a body or an id never gets a chance to be parsed as one.
const api = async (args: string[], jq?: string): Promise<string> => {
  const argv = ['api', ...args]
  if (jq) argv.push('--jq', jq)
  const { stdout } = await run('gh', argv)
  return stdout.trim()
}

const gql = (query: string, args: string[], jq?: string): Promise<string> =>
  api(['graphql', '-f', `query=${query}`, ...args], jq)

const retry = async <T>(fn: () => Promise<T>, attempts = 3): Promise<T> => {
  for (let i = 1; ; i++) {
    try {
      return await fn()
    } catch (e) {
      if (i >= attempts) throw e
      await new Promise((r) => setTimeout(r, i * 2000))
    }
  }
}

const errText = (e: unknown): string => {
  const x = e as { stderr?: string; stdout?: string; message?: string }
  return (x.stderr || x.stdout || x.message || String(e)).trim().split('\n')[0]
}

const Q_EXISTING = {
  thread: `query($id:ID!) {
    node(id:$id) { ... on PullRequestReviewThread {
      comments(first:50) { nodes { databaseId author { login } body url } }
      pullRequest { number repository { nameWithOwner } } } }
  }`,
  pr: `query($id:ID!) {
    node(id:$id) { ... on PullRequest {
      comments(last:50) { nodes { author { login } body url } } } }
  }`,
}

interface Comment {
  databaseId?: number
  author: { login: string } | null
  body: string
  url: string
}

const duplicateOf = (nodes: Comment[], body: string, viewer: string) =>
  nodes.find((n) => n.author?.login === viewer && n.body.trim() === body.trim())?.url

// A reply is the one call here that is not idempotent, so re-running a plan
// would post it twice. This read looks for it, and doubles as the source of the
// REST coordinates the reply needs.
const readThread = async (threadId: string) => {
  const raw = await gql(Q_EXISTING.thread, ['-f', `id=${threadId}`], '.data.node')
  const node: { comments: { nodes: Comment[] }; pullRequest: { number: number; repository: { nameWithOwner: string } } } =
    JSON.parse(raw)
  return {
    comments: node.comments.nodes,
    replyTo: node.comments.nodes[0]?.databaseId,
    repo: node.pullRequest.repository.nameWithOwner,
    number: node.pullRequest.number,
  }
}

const readConversation = async (prId: string): Promise<Comment[]> => {
  const raw = await gql(Q_EXISTING.pr, ['-f', `id=${prId}`], '.data.node.comments.nodes')
  return JSON.parse(raw || '[]')
}

async function postReply(item: PlanItem, viewer: string, out: Result): Promise<void> {
  if (!item.bodyFile) return
  const body = await readFile(item.bodyFile, 'utf8')

  try {
    if (item.threadId) {
      const thread = await readThread(item.threadId)
      const existing = duplicateOf(thread.comments, body, viewer)
      if (existing) {
        out.reply = 'duplicate'
        out.replyUrl = existing
        return
      }
      if (!thread.replyTo) throw new Error('thread has no comment to reply to')
      // REST, not addPullRequestReviewThreadReply: that mutation files the reply
      // under an open pending review, where only its author can read it.
      out.replyUrl = await api(
        [
          '--method',
          'POST',
          `repos/${thread.repo}/pulls/${thread.number}/comments/${thread.replyTo}/replies`,
          '-F',
          `body=@${item.bodyFile}`,
        ],
        '.html_url',
      )
    } else {
      const existing = duplicateOf(await readConversation(item.prId!), body, viewer)
      if (existing) {
        out.reply = 'duplicate'
        out.replyUrl = existing
        return
      }
      out.replyUrl = await gql(
        Q.comment,
        ['-f', `subjectId=${item.prId}`, '-F', `body=@${item.bodyFile}`],
        '.data.addComment.commentEdge.node.url',
      )
    }
    out.reply = 'ok'
  } catch (e) {
    out.reply = 'failed'
    out.err = errText(e)
  }
}

async function voteAndResolve(item: PlanItem, out: Result): Promise<Result> {
  // A thread with no reply must not end up voted and closed.
  if (out.reply === 'failed') return out

  // Both are idempotent, so both retry, and neither waits on the other.
  const [vote, resolve] = await Promise.allSettled([
    item.vote
      ? retry(() => gql(Q.vote, ['-f', `subjectId=${item.commentId}`, '-f', `content=${item.vote}`]))
      : Promise.resolve(null),
    item.resolve
      ? retry(() => gql(Q.resolve, ['-f', `threadId=${item.threadId}`]))
      : Promise.resolve(null),
  ])

  const record = (key: 'vote' | 'resolve', settled: PromiseSettledResult<unknown>, wanted: unknown) => {
    if (!wanted) return
    if (settled.status === 'fulfilled') {
      out[key] = 'ok'
      return
    }
    out[key] = 'failed'
    out.err = [out.err, errText(settled.reason)].filter(Boolean).join('; ')
  }
  record('vote', vote, item.vote)
  record('resolve', resolve, item.resolve)

  return out
}

async function pool<T, R>(items: T[], limit: number, fn: (item: T) => Promise<R>): Promise<R[]> {
  const results = new Array<R>(items.length)
  let next = 0
  const worker = async () => {
    while (next < items.length) {
      const i = next++
      results[i] = await fn(items[i])
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker))
  return results
}

function validate(plan: PlanItem[]): string[] {
  const errors: string[] = []
  plan.forEach((v, i) => {
    const at = `item ${i} (${v.ref || 'no ref'})`
    if (!v.ref) errors.push(`${at}: missing ref`)
    if (Boolean(v.threadId) === Boolean(v.prId)) errors.push(`${at}: needs exactly one of threadId or prId`)
    if (v.vote && !['THUMBS_UP', 'THUMBS_DOWN'].includes(v.vote)) errors.push(`${at}: vote must be THUMBS_UP or THUMBS_DOWN`)
    if (v.vote && !v.commentId) errors.push(`${at}: vote needs a commentId`)
    if (v.resolve && !v.threadId) errors.push(`${at}: resolve needs a threadId`)
    if (!v.bodyFile && !v.vote && !v.resolve) errors.push(`${at}: no reply, vote or resolve`)
  })
  return errors
}

const table = (rows: string[][], head: string[]): string => {
  const w = head.map((h, i) => Math.max(h.length, ...rows.map((r) => r[i].length)))
  const line = (cells: string[]) => cells.map((c, i) => c.padEnd(w[i])).join('  ').trimEnd()
  return [line(head), ...rows.map(line)].join('\n')
}

const target = process.argv[2]
if (!target || target === '-h' || target === '--help') die('usage: apply.ts PLAN.json')

const readStdin = async (): Promise<string> => {
  const chunks: Buffer[] = []
  for await (const chunk of process.stdin) chunks.push(chunk as Buffer)
  return Buffer.concat(chunks).toString('utf8')
}

const raw = target === '-'
  ? await readStdin()
  : await readFile(target, 'utf8').catch(() => die(`no such plan: ${target}`))

let plan: PlanItem[]
try {
  plan = JSON.parse(raw)
} catch (e) {
  die(`plan is not valid JSON: ${(e as Error).message}`)
}
if (!Array.isArray(plan!) || plan!.length === 0) die('plan must be a non-empty JSON array')

// Validate the whole plan before sending anything. A plan that fails halfway is
// the expensive failure, so every check happens up front.
const errors = validate(plan!)
if (errors.length) {
  console.error(`apply.ts: invalid plan\n  ${errors.join('\n  ')}`)
  process.exit(2)
}

const missing: string[] = []
for (const item of plan!) {
  if (!item.bodyFile) continue
  const body = await readFile(item.bodyFile, 'utf8').catch(() => null)
  if (!body || !body.trim()) missing.push(item.bodyFile)
}
if (missing.length) {
  console.error(`apply.ts: missing or empty body files\n  ${missing.join('\n  ')}`)
  process.exit(2)
}

const viewer = await gql('{ viewer { login } }', [], '.data.viewer.login')
const results: Result[] = plan!.map((item) => (
  { ref: item.ref, reply: 'skipped', replyUrl: '', vote: 'skipped', resolve: 'skipped', err: '' }
))

// Every reply goes out, then every vote and resolve. Rounds, not per item, so a
// vote never lands on a thread ahead of the reply that explains it.
const pairs = plan!.map((item, i) => [item, results[i]] as const)
await pool(pairs, JOBS, ([item, out]) => postReply(item, viewer, out))
await pool(pairs, JOBS, ([item, out]) => voteAndResolve(item, out))

console.log(table(results.map((r) => [r.ref, r.reply, r.vote, r.resolve]), ['REF', 'REPLY', 'VOTE', 'RESOLVE']))

const landed = results.filter((r) => r.replyUrl)
if (landed.length) console.log('\n' + landed.map((r) => `${r.ref}  ${r.replyUrl}`).join('\n'))

const failed = results.filter((r) => [r.reply, r.vote, r.resolve].includes('failed'))
if (failed.length) {
  console.error(`\n${failed.length} item(s) failed:`)
  for (const r of failed) console.error(`  ${r.ref}: ${r.err}`)
  console.error('\nA failed reply sends no vote and no resolve. Re-read those threads before retrying: GitHub sometimes posts a reply and then fails the response.')
  process.exit(1)
}
