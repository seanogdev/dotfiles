# Dotfiles

Personal macOS configuration. Some files are public in this repo. Other files are private and come from iCloud.

## Language

**iCloud Store**:
The folder in iCloud Drive that holds the private dotfiles and the fonts. It is the source of truth for them.
_Avoid_: iCloud data, iCloud dotfiles

**Mirror**:
A disposable copy of the iCloud Store, kept outside iCloud Drive on one machine. It never holds changes that the iCloud Store does not have.
_Avoid_: iCloud mirror, local copy, working copy

**Pull**:
To replace the Mirror with the current contents of the iCloud Store.
_Avoid_: Sync, mirror (as a verb)

**Install fonts**:
To copy the fonts from the iCloud Store into the system font folder.
_Avoid_: Sync
