export default {
  async fetch(request, env) {
    const res = await env.ASSETS.fetch(request);
    if (res.status === 404) {
      const url = new URL(request.url);
      if (!url.pathname.includes(".")) {
        return env.ASSETS.fetch(new Request(new URL("/index.html", url), request));
      }
    }
    return res;
  },
};
