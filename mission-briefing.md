# Mission briefing — The Server Room Incident

> From: CEO, ACME Corp
> To: Incident Response Team (that's you)
>
> Someone deleted a backup file from one of our web servers last night,
> 30 October, between 10 PM and midnight. I don't know which server,
> I don't know who, I don't know what they deleted. You have the whole
> company file tree. Find out.

Your world lives in `~/acme-corp`. Run `./check` any time to see where
you are. Each task below is checked by `./check N` (or `./check N ANSWER`
for questions).

Before you start, five keys that will save you an hour of typing:

| Key | Does |
|---|---|
| `Tab` | finishes the file name for you. Press twice to see options. |
| `↑` | brings back the last command. Edit it, run again. |
| `Ctrl+C` | stops whatever is running. Your escape hatch. |
| `Ctrl+L` | clears the screen. |
| `q` | gets you out of `less`. |

---

## Act 1 — Get your bearings  (`pwd` `ls` `cd` `cat`)

You've been dropped into a company you've never seen. Look around.

1. **Find the secret key hidden in the company root.** Something in
   `~/acme-corp` doesn't show up in a normal listing.
   `./check 1 KEY-....`
2. **Which of the four web servers has the real nginx access log?**
   Servers live under `infra/servers/`. Three of them are decoys.
   `./check 2 web-0X`

## Act 2 — Gather evidence  (`mkdir` `cp` `mv` `rm` `head` `tail` `less`)

Investigators don't work on the originals. Build an evidence folder.

3. **Create `evidence/` in the company root and copy the access log into it.**
   `./check 3`
4. **What time (HH:MM:SS) was the very last request in the log?**
   10,000 lines. Don't read them all.
   `./check 4 23:xx:xx`
5. **Finance saved a file with a terrible name: `Q3 Report final (2).docx`.
   Rename it to `q3-report-final.docx`.** Spaces and brackets fight back.
   `./check 5`
6. **`tmp/` has 300 junk `.tmp` files. Delete all of them — and nothing else.**
   There's a file in there that must survive.
   `./check 6`

## Act 3 — Find the culprit  (`grep` `|` `>` `cut` `sort` `uniq` `wc`)

This is the part real sysadmins do every day.

7. **Save only the last 500 lines of the log (last night) as `evidence/lastnight.log`.**
   `./check 7`
8. **How many DELETE requests are in last night's log?**
   `./check 8 N`
9. **Which IP address made the most DELETE requests last night?**
   Warning: if you search the whole month instead of last night, you'll
   catch the wrong "criminal".
   `./check 9 10.0.x.y`
10. **Which employee owns that IP?** Somewhere in the company tree, a file
    maps IPs to people. You don't know where it is. Search everything.
    `./check 10 first.last`
11. **Which file did they actually delete?** Most of their DELETEs were
    refused (403). Exactly one succeeded (200).
    `./check 11 /backups/...`

## Act 4 — Lock it down  (`chmod` `ls -l` `du` `ps` `kill` `>>`)

12. **Make `evidence/lastnight.log` read-only.** Nobody tampers with evidence.
    `./check 12`
13. **Which folder under `projects/` is eating the disk?**
    `./check 13 name`
14. **Run `./start-services`. Three background services start. One is a
    crypto-miner. Kill it — and only it.**
    `./check 14`
15. **Write your report:** `evidence/report.txt` must contain the culprit's
    IP, their username and the deleted file. Build it line by line with
    `echo` and `>>`.
    `./check 15`

Then: `./submit`

---

## Bonus (if you finish early)

Put your Act 3 pipeline into a file called `hunt.sh`, make it executable
with `chmod +x hunt.sh`, and run it with `./hunt.sh`. Congratulations —
that's a shell script.

Second bonus: `find . -name "*.docx"` — now find every file over 1 MB
without being told how.
