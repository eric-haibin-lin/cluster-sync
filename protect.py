import glob
import subprocess

repo = "test-protect"
np = 8
bs = 8196
acc = 2
start = -1
lr = 0.0001
warm = 0.01
total_steps = 3000000


while True:
    checkpoints = sorted(glob.glob('/fsx/experiment/' + repo + "/ckpt/*.params"))
    steps = []
    for ckpt in checkpoints:
        step = int(ckpt.split('/')[-1].split('.')[0])
        steps.append(step)
        if step >= total_steps:
            exit()

    checkpoints = sorted(glob.glob('/fsx/experiment/' + repo + "/ckpt/*.state*"))
    max_step = -1
    for ckpt in checkpoints:
        step = int(ckpt.split('/')[-1].split('.')[0])
        if step in steps and max_step < step:
            max_step = step
    print('Found max_step = ', max_step)
    start = max_step

    cmd = ["bash", "run.sh", 'base', 'web-book-wiki-uncased', '/home/ubuntu/hosts', str(start), str(np), 'raw', str(bs), str(acc), str(lr), str(warm), str(total_steps), 'py35', repo]
    print("Running ", cmd)
    subprocess.call(cmd)