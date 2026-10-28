# The Server Room Incident — a hands-on Linux workshop

Someone deleted a backup file from an ACME Corp web server last night.
You have the company's entire file tree and a terminal. Find the server,
the night, the culprit and the file.

Along the way you will use every command a Linux beginner needs:
`pwd ls cd mkdir cp mv rm cat less head tail grep find cut sort uniq`,
pipes, redirection, `chmod`, `du`, `ps`, `kill`.

## Setup (2 minutes)

Open **Git Bash** (Windows) or a terminal (Linux / Mac), then:

```bash
git clone https://github.com/cladius/linux-workshop-student-edition.git
cd linux-workshop-student-edition
bash setup.sh
```

It asks for your ID — your first name plus your roll number, e.g. `priya07` — and builds your own copy of ACME Corp in
`~/acme-corp`. Your copy is different from your neighbour's — same
story, different culprit — so compare *commands*, not answers.

No git? Download the ZIP, extract it, open Git Bash inside the folder,
run `bash setup.sh`.

## Playing

```bash
cd ~/acme-corp
./check              # where am I, what's next
./check 1 KEY-...    # answer a question
./check 3            # tell it to verify something you changed
./submit             # when all 15 are done
```

Wrong answers give you a hint. A second wrong answer gives a bigger hint.
A third gives you the command. There is no penalty for wrong answers
except pride.

Messed up your world (deleted too much)? `bash setup.sh` again, same
ID, answer `y` to wipe.

## What's in this repo

| Path | For |
|---|---|
| `setup.sh` | builds the world (run this) |
| `bin/` | `check`, `submit`, `start-services` — copied into your world |
| `mission-briefing.md` | the story and the 4 acts — read this |
| `cheatsheet.md` | one page of commands — print this |
