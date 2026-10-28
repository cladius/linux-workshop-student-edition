#!/usr/bin/env bash
# =====================================================================
#  ACME Corp — "The Server Room Incident"
#  World generator for the Linux workshop.
#
#  Usage:   bash setup.sh            (asks for your ID, e.g. priya07)
#           bash setup.sh priya07   (ID given directly)
#
#  Creates  ~/acme-corp   (or $WORKSHOP_HOME/acme-corp)
#  Everything inside is generated from your ID, so your evidence,
#  culprit and answers are different from your neighbour's.
# =====================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 1. Who are you? ----------------------------------------
NAME="${1:-}"
while [ -z "$NAME" ]; do
  printf 'Your first name + roll number, e.g. priya07 (this seeds your world): '
  read -r NAME
done
NAME="$(printf '%s' "$NAME" | tr -d '\r' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
SEED=$(( $(printf '%s' "$NAME" | cksum | cut -d' ' -f1) % 1000000 ))

# ---------- 2. Where does the world live? -------------------------
BASE="${WORKSHOP_HOME:-$HOME}"
if ! { mkdir -p "$BASE" 2>/dev/null && [ -w "$BASE" ]; }; then
  BASE="/tmp"
fi
ROOT="$BASE/acme-corp"

if [ -d "$ROOT" ]; then
  printf '%s already exists. Wipe it and start fresh? [y/N] ' "$ROOT"
  read -r yn
  case "$yn" in
    y|Y) rm -rf "$ROOT" ;;
    *)   echo "Keeping the existing world. Done."; exit 0 ;;
  esac
fi

echo
echo "Building ACME Corp for $NAME (seed $SEED) in $ROOT ..."
mkdir -p "$ROOT"
cd "$ROOT" || exit 1

# ---------- 3. Seeded helpers --------------------------------------
RANDOM=$SEED
pick() { local n=$#; local i=$(( RANDOM % n + 1 )); printf '%s' "${!i}"; }
rnd()  { printf '%d' $(( RANDOM % ($2 - $1 + 1) + $1 )); }   # rnd MIN MAX
cap()  { printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'; }

FIRST=(aarav vivaan aditya vihaan arjun sai reyansh krishna ishaan shaurya
       ananya diya saanvi aadhya kiara pari myra anika navya riya
       rahul neha karan pooja amit sneha rohan divya nikhil tanvi
       varun meera siddharth isha kunal shreya manish nidhi akash swati
       deepak kavya rajat ritika gaurav simran harsh preeti vikram juhi)
LAST=(sharma verma patel reddy nair iyer gupta singh mehta joshi
      kulkarni deshpande rao pillai menon bose das chatterjee khan shah)
DEPTS=(engineering finance hr sales marketing support legal ops)

# ---------- 4. Directory skeleton -----------------------------------
mkdir -p hr/policies finance/invoices/2026 projects tmp infra/vpn infra/run \
         .secrets evidence-template
for s in web-01 web-02 web-03 web-04; do
  mkdir -p "infra/servers/$s/var/log" "infra/servers/$s/etc"
done
mkdir -p projects/alpha/src projects/beta/src projects/legacy/build projects/website/css

# ---------- 5. Employees + VPN map ----------------------------------
NEMP=48
CULPRIT_IDX=$(rnd 0 $((NEMP-1)))
: > hr/employees.csv
echo "id,username,full_name,department,joined" >> hr/employees.csv
: > infra/vpn/assignments.txt
printf '# VPN static IP assignments — do not edit by hand\n# ip            username            dept\n' >> infra/vpn/assignments.txt
CULPRIT_USER=""; CULPRIT_IP=""
declare -a USERS IPS
for i in $(seq 0 $((NEMP-1))); do
  while :; do
    f=$(pick "${FIRST[@]}"); l=$(pick "${LAST[@]}")
    u="$f.$l"
    grep -q ",$u," hr/employees.csv || break
  done
  d=$(pick "${DEPTS[@]}")
  while :; do
    ip="10.0.$(rnd 10 99).$(rnd 2 250)"
    grep -q "^$ip " infra/vpn/assignments.txt || break
  done
  USERS[$i]=$u; IPS[$i]=$ip
  printf '%d,%s,%s %s,%s,20%02d-%02d-%02d\n' $((i+1)) "$u" "$(cap "$f")" "$(cap "$l")" "$d" $(rnd 15 26) $(rnd 1 12) $(rnd 1 28) >> hr/employees.csv
  printf '%-15s %-20s %s\n' "$ip" "$u" "$d" >> infra/vpn/assignments.txt
  if [ "$i" -eq "$CULPRIT_IDX" ]; then CULPRIT_USER=$u; CULPRIT_IP=$ip; fi
done
# two decoy IPs that also issue a few DELETEs on the incident night
DECOY1_IP=${IPS[$(( (CULPRIT_IDX+7)  % NEMP ))]}
DECOY2_IP=${IPS[$(( (CULPRIT_IDX+19) % NEMP ))]}
# the cleanup bot: most DELETEs in the WHOLE log, but all harmless /tmp paths
BOT_IP="10.0.0.9"

printf '# Service accounts\n%-15s %-20s %s\n' "$BOT_IP" "cleanup-bot" "ops" >> infra/vpn/assignments.txt

cat > hr/policies/acceptable-use.txt <<'EOF'
ACME CORP — ACCEPTABLE USE POLICY (v3)

1. Company data stays on company systems.
2. Backups live under /backups on the production web servers and are
   never to be deleted without a change ticket.
3. All VPN users get a static IP. The mapping is maintained by Ops in
   infra/vpn/assignments.txt.
4. Mining cryptocurrency on company hardware is a fireable offence.
EOF

# ---------- 6. The secret key (Act 1) -------------------------------
KEY="KEY-$(rnd 1000 9999)-$(pick ALPHA BRAVO DELTA ECHO FOXTROT KILO LIMA NOVA OSCAR ZULU)"
printf 'vault access key:\n%s\n\nDo not share. Seriously.\n' "$KEY" > .secrets/vault.key
cat > .secrets/.env <<'EOF'
DB_PASSWORD=hunter2
API_TOKEN=sk-live-DO-NOT-COMMIT
EOF

# ---------- 7. Which server has the real nginx log? -----------------
SERVER="web-0$(rnd 1 4)"
for s in web-01 web-02 web-03 web-04; do
  printf 'hostname %s\nrole webserver\n' "$s" > "infra/servers/$s/etc/hostname.conf"
  if [ "$s" = "$SERVER" ]; then
    mkdir -p "infra/servers/$s/var/log/nginx"
  else
    mkdir -p "infra/servers/$s/var/log/nginx"
    printf '%s: nginx not configured on this host (see web-xx)\n' "$s" > "infra/servers/$s/var/log/nginx/README"
    printf 'Oct 30 03:00:01 %s CRON[%d]: logrotate ok\n' "$s" $(rnd 1000 9999) > "infra/servers/$s/var/log/syslog"
  fi
done
LOGDIR="infra/servers/$SERVER/var/log/nginx"

# ---------- 8. The access log (10 000 lines) ------------------------
DELETED=$(pick "/backups/customers.db" "/backups/payroll-2026.xlsx" "/backups/source-archive.tar.gz" "/backups/patents-q3.zip")
NCULPRIT=$(rnd 11 16)      # culprit DELETEs in the last 500 lines
ND1=$(rnd 1 3); ND2=$(rnd 1 2)

awk -v seed="$SEED" -v culprit="$CULPRIT_IP" -v d1="$DECOY1_IP" -v d2="$DECOY2_IP" \
    -v bot="$BOT_IP" -v deleted="$DELETED" -v nc="$NCULPRIT" -v nd1="$ND1" -v nd2="$ND2" \
    -v ips="$(printf '%s ' "${IPS[@]}")" '
BEGIN {
  srand(seed);
  n = split(ips, IP, " ");
  split("/ /index.html /login /dashboard /api/v1/orders /api/v1/customers /static/app.js /static/style.css /reports/q3.pdf /images/logo.png /about /pricing /api/v1/invoices /health", PATHS, " ");
  split("GET GET GET GET GET GET POST GET PUT GET", METH, " ");
  split("200 200 200 200 304 200 404 200 500 200", CODE, " ");
  split("Mozilla/5.0 Mozilla/5.0 curl/8.4.0 Mozilla/5.0 PostmanRuntime/7.36", UA, " ");
  split("/backups/customers.db /backups/payroll-2026.xlsx /backups/source-archive.tar.gz /backups/patents-q3.zip /backups/old /backups/README", BK, " ");

  TOTAL = 10000; NIGHT = 500;
  # Lines 1..9500: 1 Oct .. 30 Oct 21:59   ; lines 9501..10000: 30 Oct 22:00 .. 23:59
  for (i = 1; i <= TOTAL; i++) {
    if (i <= TOTAL - NIGHT) {
      day = 1 + int((i - 1) / ((TOTAL - NIGHT) / 30.0)); if (day > 30) day = 30;
      hh = int(rand() * 22); if (day == 30 && hh > 21) hh = 21;
      mm = int(rand() * 60); ss = int(rand() * 60);
    } else {
      day = 30;
      k = i - (TOTAL - NIGHT);              # 1..500 over 120 minutes
      mins = int((k - 1) * 120 / NIGHT);
      hh = 22 + int(mins / 60); mm = mins % 60; ss = int(rand() * 60);
    }
    ts = sprintf("%02d/Oct/2026:%02d:%02d:%02d +0530", day, hh, mm, ss);

    ip = IP[1 + int(rand() * n)];
    m  = METH[1 + int(rand() * 10)];
    p  = PATHS[1 + int(rand() * 14)];
    c  = CODE[1 + int(rand() * 10)];
    ua = UA[1 + int(rand() * 5)];
    sz = int(rand() * 20000);

    # the cleanup bot: harmless DELETEs sprinkled through the whole month (~60)
    if (i <= TOTAL - NIGHT && rand() < 0.0065) {
      ip = bot; m = "DELETE"; p = sprintf("/tmp/session-%05d.tmp", int(rand() * 99999)); c = "204"; sz = 0; ua = "acme-cleanup/1.2";
    }
    LINE[i] = sprintf("%s - - [%s] \"%s %s HTTP/1.1\" %s %d \"-\" \"%s\"", ip, ts, m, p, c, sz, ua);
    TS[i] = ts;
  }

  # --- the incident, inside the last 500 lines ---
  # culprit: nc DELETEs; all 403 except exactly one 200 on the real target
  for (j = 1; j <= nc; j++) {
    pos = TOTAL - NIGHT + 40 + int(rand() * (NIGHT - 80));
    while (pos in USED) pos = TOTAL - NIGHT + 40 + int(rand() * (NIGHT - 80));
    USED[pos] = 1;
    tgt = BK[1 + int(rand() * 6)]; if (tgt == deleted) tgt = "/backups/old";
    LINE[pos] = sprintf("%s - - [%s] \"DELETE %s HTTP/1.1\" 403 0 \"-\" \"curl/8.4.0\"", culprit, TS[pos], tgt);
  }
  pos = TOTAL - 60 - int(rand() * 100);
  while (pos in USED) pos--;
  USED[pos] = 1;
  LINE[pos] = sprintf("%s - - [%s] \"DELETE %s HTTP/1.1\" 200 0 \"-\" \"curl/8.4.0\"", culprit, TS[pos], deleted);

  # decoys: a few 403 DELETEs each
  for (j = 1; j <= nd1; j++) { pos = TOTAL - NIGHT + 10 + int(rand() * (NIGHT - 20)); while (pos in USED) pos++; USED[pos] = 1;
    LINE[pos] = sprintf("%s - - [%s] \"DELETE /api/v1/orders/%d HTTP/1.1\" 403 0 \"-\" \"Mozilla/5.0\"", d1, TS[pos], int(rand() * 900)); }
  for (j = 1; j <= nd2; j++) { pos = TOTAL - NIGHT + 10 + int(rand() * (NIGHT - 20)); while (pos in USED) pos++; USED[pos] = 1;
    LINE[pos] = sprintf("%s - - [%s] \"DELETE /tmp/cache.lock HTTP/1.1\" 403 0 \"-\" \"Mozilla/5.0\"", d2, TS[pos], 0); }

  for (i = 1; i <= TOTAL; i++) print LINE[i];
}' > "$LOGDIR/access.log"

# rotated + error logs, for realism and for `ls -l` / `du`
head -n 3000 "$LOGDIR/access.log" | sed 's/Oct\/2026/Sep\/2026/' > "$LOGDIR/access.log.1"
{
  for i in $(seq 1 40); do
    printf '2026/10/%02d %02d:%02d:%02d [error] 1234#0: *%d open() failed (2: No such file) client: 10.0.%d.%d\n' \
      $(rnd 1 30) $(rnd 0 23) $(rnd 0 59) $(rnd 0 59) $(rnd 1000 9999) $(rnd 10 99) $(rnd 2 250)
  done
  printf '2026/10/30 23:58:11 [warn] 1234#0: *9001 /backups directory listing enabled — check config\n'
} > "$LOGDIR/error.log"

# ---------- 9. Projects (du / find material) ------------------------
cat > projects/alpha/README.md <<'EOF'
# Project Alpha
Customer portal rewrite. Owner: engineering.
EOF
printf 'def main():\n    print("alpha")\n\nif __name__ == "__main__":\n    main()\n' > projects/alpha/src/main.py
printf 'import json\n\ndef load(path):\n    return json.load(open(path))\n' > projects/alpha/src/util.py
printf '# Project Beta\nInternal billing service.\n' > projects/beta/README.md
printf 'package main\n\nfunc main() {}\n' > projects/beta/src/main.go
printf '<!doctype html><title>ACME</title><h1>Welcome to ACME</h1>\n' > projects/website/index.html
printf 'body { font-family: sans-serif; }\n' > projects/website/css/style.css
printf '# Legacy\nDO NOT TOUCH. Nobody knows what this does.\n' > projects/legacy/README.md
# the disk hog
dd if=/dev/zero of=projects/legacy/build/core.dump bs=1024 count=$(( 7000 + $(rnd 0 2000) )) 2>/dev/null
printf 'TODO: delete core.dump someday\n' > projects/legacy/build/notes.txt

# ---------- 10. Junk for rm/glob practice ---------------------------
for i in $(seq 1 300); do printf 'cache %d\n' "$i" > "tmp/cache_$(printf '%04d' "$i").tmp"; done
printf 'IMPORTANT — do not delete this file. It is not a .tmp file.\n' > tmp/keep-me.txt
printf 'random notes\n' > tmp/notes.txt

# ---------- 11. Finance, incl. a file name with spaces --------------
for i in $(seq 1 60); do
  printf 'INVOICE %04d\nAmount: INR %d\n' "$i" $(rnd 5000 90000) > "finance/invoices/2026/invoice-$(printf '%04d' "$i").txt"
done
printf 'Q3 report — final final (2)\nRevenue up 12%%.\n' > "finance/Q3 Report final (2).docx"
printf 'Q2 report\n' > "finance/q2-report.docx"

# ---------- 12. Welcome note ----------------------------------------
cat > README.txt <<EOF
From: CEO <ceo@acme.example>
To:   Incident Response Team
Subj: URGENT — something happened on the web servers last night (30 Oct)

Someone deleted a backup file from one of our web servers between
10 PM and midnight. I don't know which server, I don't know who,
I don't know what they deleted.

You have the whole company file tree in front of you. Find out.

Start with:   ./check

Good luck.
EOF

# ---------- 13. Tooling + answer key (hashed) -----------------------
cp "$HERE/bin/check" "$HERE/bin/submit" "$HERE/bin/start-services" . 2>/dev/null || {
  echo "ERROR: could not find bin/check next to setup.sh. Run setup.sh from the workshop folder." >&2; exit 1; }
chmod +x check submit start-services 2>/dev/null
cp -r "$HERE/bin/services" infra/services

mkdir -p .state
h() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | md5sum | cut -d' ' -f1; }

LAST_TS=$(tail -n 1 "$LOGDIR/access.log" | sed 's/.*:\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\) .*/\1/')
NDEL=$(tail -n 500 "$LOGDIR/access.log" | grep -c DELETE)
BIG=$(du -sk projects/* | sort -n | tail -n 1 | awk '{print $2}' | sed 's#projects/##')

{
  echo "name=$NAME"
  echo "seed=$SEED"
  echo "start=$(date +%s)"
  echo "server=$SERVER"
  echo "a1=$(h "$KEY")"
  echo "a2=$(h "$SERVER")"
  echo "a4=$(h "$LAST_TS")"
  echo "a8=$(h "$NDEL")"
  echo "a9=$(h "$CULPRIT_IP")"
  echo "a10=$(h "$CULPRIT_USER")"
  echo "a11=$(h "$DELETED")"
  echo "a13=$(h "$BIG")"
} > .state/meta
: > .state/done
: > .state/attempts

# ---------- 14. Done -----------------------------------------------
echo
echo "Done. Your world is ready:"
echo
echo "    cd $ROOT"
echo "    ./check"
echo
