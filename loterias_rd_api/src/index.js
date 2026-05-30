import { parseLotteryResults } from './parser.js';

const DEFAULT_SOURCE_URL = 'https://loteriasdominicanas.com/';
const DEFAULT_CACHE_SECONDS = 180;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders() });
    }

    if (url.pathname === '/health') {
      return json({ ok: true, service: 'loterias-rd-api' });
    }

    if (url.pathname === '/' || url.pathname === '/results') {
      return handleResults(request, env, ctx);
    }

    return json({ error: 'Ruta no encontrada' }, { status: 404 });
  },
};

async function handleResults(request, env, ctx) {
  const sourceUrl = env.SOURCE_URL || DEFAULT_SOURCE_URL;
  const cacheSeconds = Number(env.CACHE_SECONDS || DEFAULT_CACHE_SECONDS);
  const cache = caches.default;
  const cacheKey = new Request(new URL('/results', request.url).toString(), request);

  const cachedResponse = await cache.match(cacheKey);
  if (cachedResponse) {
    return withCors(cachedResponse);
  }

  try {
    const sourceResponse = await fetch(sourceUrl, {
      headers: {
        Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'User-Agent': 'LoteriasRDAPI/1.0 (+https://workers.cloudflare.com/)',
      },
      cf: {
        cacheTtl: cacheSeconds,
        cacheEverything: false,
      },
    });

    if (!sourceResponse.ok) {
      return json(
        {
          error: 'No se pudo consultar la fuente de resultados.',
          status: sourceResponse.status,
          source: sourceUrl,
        },
        { status: 502 },
      );
    }

    const html = await sourceResponse.text();
    const results = parseLotteryResults(html);

    if (results.length === 0) {
      return json(
        {
          error: 'La fuente respondio, pero no se encontraron resultados legibles.',
          source: sourceUrl,
          updatedAt: new Date().toISOString(),
          results: [],
        },
        { status: 502 },
      );
    }

    const response = json({
      source: sourceUrl,
      updatedAt: new Date().toISOString(),
      count: results.length,
      results,
    });

    response.headers.set('Cache-Control', `public, max-age=${cacheSeconds}`);
    ctx.waitUntil(cache.put(cacheKey, response.clone()));
    return response;
  } catch (error) {
    return json(
      {
        error: 'Error inesperado consultando resultados.',
        detail: error instanceof Error ? error.message : String(error),
      },
      { status: 500 },
    );
  }
}

function json(payload, init = {}) {
  const headers = new Headers(init.headers || {});
  headers.set('Content-Type', 'application/json; charset=utf-8');
  for (const [key, value] of Object.entries(corsHeaders())) {
    headers.set(key, value);
  }

  return new Response(JSON.stringify(payload, null, 2), {
    ...init,
    headers,
  });
}

function withCors(response) {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(corsHeaders())) {
    headers.set(key, value);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}
