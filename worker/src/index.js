export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // CORS headers to allow your frontend to upload
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, PUT, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Upload a file to R2
    if (request.method === 'PUT' && url.pathname.startsWith('/upload/')) {
      const fileName = decodeURIComponent(url.pathname.split('/upload/')[1]);
      
      // Store the stream directly in R2 (can handle files up to 5GB)
      await env.SCANS_BUCKET.put(fileName, request.body);
      
      return new Response(JSON.stringify({ 
        success: true, 
        url: `${url.origin}/download/${encodeURIComponent(fileName)}` 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Download a file from R2
    if (request.method === 'GET' && url.pathname.startsWith('/download/')) {
      const fileName = decodeURIComponent(url.pathname.split('/download/')[1]);
      
      const object = await env.SCANS_BUCKET.get(fileName);
      if (!object) {
        return new Response('File not found', { status: 404, headers: corsHeaders });
      }

      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set('etag', object.httpEtag);
      for (const [key, value] of Object.entries(corsHeaders)) {
        headers.set(key, value);
      }

      return new Response(object.body, { headers });
    }

    return new Response('Footshape Storage API Active', { headers: corsHeaders });
  }
};
