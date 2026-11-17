import {NextRequest} from 'next/server';
import {authenticated,problem} from '@/lib/server';
export async function GET(req:NextRequest){try{const {db,user}=await authenticated(req);const {data,error}=await db.from('payment_orders').select('order_id,payment_id,plan,amount,paid_at,status').eq('user_id',user.id).eq('status','paid').order('paid_at',{ascending:false}).limit(1);if(error)throw error;return Response.json({receipt:data?.[0]||null})}catch(e){return problem(e,401)}}
