import {createClient} from '@supabase/supabase-js';
import type {NextRequest} from 'next/server';
export function getAdmin(){const url=process.env.NEXT_PUBLIC_SUPABASE_URL;const key=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!url||!key)throw new Error('Supabase admin is not configured');return createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}})}
export async function authenticated(req:NextRequest){const token=req.headers.get('authorization')?.replace(/^Bearer\s+/i,'');if(!token)throw new Error('Sign in required');const db=getAdmin();const {data,error}=await db.auth.getUser(token);if(error||!data.user)throw new Error('Session invalid or expired');return {db,user:data.user,token};}
export function problem(error:unknown,status=400){return Response.json({error:error instanceof Error?error.message:'Request failed'},{status})}
