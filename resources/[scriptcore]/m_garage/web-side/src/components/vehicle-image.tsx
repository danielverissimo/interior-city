import { useEffect, useState } from "react";

const silhouette = "./images/default_vehicle.webp";
const pendingPhotos = new Map<string, Promise<string | undefined>>();
const resolvedPhotos = new Map<string, string | undefined>();

function resolvePhoto(src: string, bundled: string, key: string) {
  const pending = pendingPhotos.get(key);
  if (pending) return pending;

  const configured = src.trim();
  const candidates = configured.startsWith("./") ? [configured, bundled] : [bundled, configured];
  const urls = [...new Set(candidates.filter(Boolean))];
  const result = (async () => {
    for (const url of urls) {
      const loaded = await new Promise<boolean>((resolve) => {
        const image = new Image();
        const finish = (ok: boolean) => {
          window.clearTimeout(timeout);
          image.onload = image.onerror = null;
          resolve(ok);
        };
        const timeout = window.setTimeout(() => finish(false), 4000);
        image.onerror = () => finish(false);
        image.onload = () => finish(image.naturalWidth > 0);
        image.src = url;
      });
      if (loaded) return url;
    }
    return undefined;
  })().then((photo) => {
    resolvedPhotos.set(key, photo);
    pendingPhotos.delete(key);
    return photo;
  });
  pendingPhotos.set(key, result);
  return result;
}

export function VehicleImage({ model, src = "", className }: { model: string; src?: string; className: string }) {
  const bundled = /^[a-z0-9_-]+$/i.test(model) ? "./images/catalog/" + model.toLowerCase() + ".webp" : "";
  const key = bundled + "\n" + src;
  const [loaded, setLoaded] = useState<{ key: string; photo?: string }>();
  const photo = loaded?.key === key ? loaded.photo : resolvedPhotos.get(key);

  useEffect(() => {
    let current = true;
    if (!resolvedPhotos.has(key)) {
      void resolvePhoto(src, bundled, key).then((url) => {
        if (current) setLoaded({ key, photo: url });
      });
    }
    return () => { current = false; };
  }, [key, src, bundled]);

  return (
    <span className={className} data-photo={Boolean(photo)} aria-hidden="true">
      <img src={photo || silhouette} alt="" draggable={false} onError={photo ? () => {
        resolvedPhotos.set(key, undefined);
        setLoaded({ key });
      } : undefined} />
    </span>
  );
}
