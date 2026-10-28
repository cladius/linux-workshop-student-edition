# Linux command reference — one page

Syntax is always `command  -options  arguments`. Options start with `-`.
`command --help` explains any of them. Paths: `.` = here, `..` = one up,
`~` = home, `/` = root of everything.

## Where am I, what's here
| | |
|---|---|
| `pwd` | print working directory (where am I) |
| `ls` | list files · `ls -l` details · `ls -a` incl. hidden · `ls -lh` human sizes |
| `cd dir` | go into dir · `cd ..` go up · `cd` go home · `cd -` go back |

## Make, copy, move, delete
| | |
|---|---|
| `mkdir name` | make a folder · `mkdir -p a/b/c` make the whole path |
| `touch file` | make an empty file |
| `cp src dst` | copy · `cp -r dir dst` copy a folder |
| `mv src dst` | move **or rename** |
| `rm file` | delete (no undo!) · `rm -r dir` delete folder |
| `*` | wildcard: `*.tmp` = every file ending in .tmp. **`ls` it before you `rm` it.** |
| `"quotes"` | around names with spaces: `mv "my file.txt" myfile.txt` |

## Look inside files
| | |
|---|---|
| `cat file` | print whole file (small files only) |
| `less file` | scroll through a big file · `q` quits · `/word` searches |
| `head file` | first 10 lines · `head -n 20 file` |
| `tail file` | last 10 lines · `tail -n 500 file` |
| `wc -l file` | count lines |

## Search
| | |
|---|---|
| `grep word file` | lines containing word · `-i` ignore case · `-c` count · `-n` line numbers |
| `grep -r word dir` | search every file under dir |
| `find dir -name "*.log"` | find files by name · `-size +1M` bigger than 1 MB · `-type d` folders only |

## Plumbing
| | |
|---|---|
| `cmd > file` | send output into file (overwrites) |
| `cmd >> file` | append to file |
| `cmd1 \| cmd2` | pipe: output of cmd1 becomes input of cmd2 |
| `cut -d' ' -f1` | keep the 1st space-separated column |
| `sort` | sort lines · `sort -n` numerically · `sort -h` human sizes |
| `uniq -c` | collapse repeated lines and count them (sort first!) |
| `echo text` | print text (useful with `>` and `>>`) |

**The pattern you'll use forever:**
`grep THING file | cut -d' ' -f1 | sort | uniq -c | sort -n | tail -n 1`
= "which THING-doer appears most?"

## Permissions, disk, processes
| | |
|---|---|
| `ls -l` | `-rw-r--r--` = owner **r**ead **w**rite, group read, others read |
| `chmod 444 file` | read-only for all · `chmod +x script` make executable · `chmod 644 file` back to normal |
| `du -sh dir/*` | disk used by each thing in dir |
| `df -h` | disk free, per drive |
| `ps` | running processes (with PIDs) · `ps -ef` all of them |
| `kill PID` | stop a process · `kill -9 PID` stop it *now* |

## Keys
`Tab` complete · `↑` last command · `Ctrl+C` stop · `Ctrl+L` clear · `Ctrl+R` search history · `q` quit less
