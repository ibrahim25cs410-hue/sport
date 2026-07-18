import cv2
from pathlib import Path

src = r"C:\Users\user\OneDrive\Desktop\صضثيبلا.mp4"
out = Path(r"d:\sport\_video_review")
out.mkdir(exist_ok=True)
for p in out.glob("frame_*.jpg"):
    p.unlink()

cap = cv2.VideoCapture(src)
if not cap.isOpened():
    raise SystemExit("cannot open video")

fps = cap.get(cv2.CAP_PROP_FPS) or 30
n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
dur = n / fps if fps else 0
print(f"fps={fps:.2f} frames={n} size={w}x{h} duration={dur:.1f}s")

interval = max(1, int(fps * 1.5))
idxs = set(range(0, max(n, 1), interval))
if n > 0:
    idxs.add(n - 1)
idxs = sorted(idxs)

saved = 0
for i, idx in enumerate(idxs):
    cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
    ok, frame = cap.read()
    if not ok:
        continue
    scale = 720 / max(frame.shape[1], 1)
    if scale < 1:
        frame = cv2.resize(
            frame, (int(frame.shape[1] * scale), int(frame.shape[0] * scale))
        )
    t = idx / fps
    path = out / f"frame_{i:03d}_t{t:05.1f}s.jpg"
    cv2.imwrite(str(path), frame, [int(cv2.IMWRITE_JPEG_QUALITY), 85])
    saved += 1

cap.release()
print(f"saved={saved}")
for p in sorted(out.glob("frame_*.jpg")):
    print(p.name, p.stat().st_size)
