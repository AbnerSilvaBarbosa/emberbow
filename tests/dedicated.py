"""Real dedicated-server test: one headless server and three clients on localhost."""
import subprocess, sys, time
from pathlib import Path
root = Path(__file__).resolve().parents[1]
engine = str(Path(sys.argv[1]).resolve())
def launch(script, flag=None):
    cmd = [engine, '--headless', '--log-file', '/tmp/emberbow-dedicated-' + str(time.time_ns()) + '.log', '--path', str(root), '--script', script]
    if flag: cmd += ['--', flag]
    return subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
processes = []
try:
    server = launch('tests/dedicated.gd', '--server'); processes.append(server)
    time.sleep(1.5)
    for _ in range(3):
        processes.append(launch('tests/dedicated_client.gd'))
        time.sleep(0.2)
    failed = False
    for i, proc in enumerate(processes):
        output = proc.communicate(timeout=45)[0]
        print(output)
        expected = 'DEDICATED_SERVER_PASS' if i == 0 else 'DEDICATED_CLIENT_PASS'
        failed |= bool(proc.returncode or expected not in output or 'SCRIPT ERROR' in output or 'above the MTU' in output)
    sys.exit(1 if failed else 0)
finally:
    for proc in processes:
        if proc.poll() is None: proc.kill()
