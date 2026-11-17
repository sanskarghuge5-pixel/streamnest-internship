import { createClient, SupabaseClient } from '@supabase/supabase-js';
const url=process.env.NEXT_PUBLIC_SUPABASE_URL||'';
const key=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY||'';
export const configured=Boolean(url && key && url.startsWith('https://') && !url.includes('YOUR_PROJECT'));
export const supabase: SupabaseClient|null=configured?createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null;
