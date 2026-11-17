import {NextRequest} from 'next/server';
import {authenticated,problem} from '@/lib/server';
export async function POST(req:NextRequest){try{const {db,user,token}=await authenticated(req);const {videoId}=await req.json();if(typeof videoId!=='string')return problem('Invalid video');const {data:video,error}=await db.from('videos').select('id,title,video_url,is_premium').eq('id',videoId).single();if(error||!video)return problem('Video not found',404);
// RPC runs atomically in PostgreSQL and validates both the plan and the daily quota.
const {createClient}=await import('@supabase/supabase-js');const client=createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,{global:{headers:{Authorization:`Bearer ${token}`}},auth:{persistSession:false,autoRefreshToken:false}});
const {error:quotaError}=await client.rpc('register_download',{p_video_id:videoId});if(quotaError)return problem(quotaError.message,403);
if(video.video_url.startsWith('private/')){const {data,error:signError}=await db.storage.from('videos').createSignedUrl(video.video_url.slice(8),90,{download:`${video.title.replace(/[^a-z0-9 _-]/gi,'')||'video'}.mp4`});if(signError||!data)throw signError||new Error('Cannot sign download');return Response.json({url:data.signedUrl,message:'Download authorized'})}
// Seed videos are publicly licensed samples; quota applies to this application, not third-party source URLs.
return Response.json({url:video.video_url,message:'Download authorized for public sample'});
}catch(e){return problem(e,401)}}
