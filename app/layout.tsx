import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata={title:'StreamNest | Watch Together',description:'A responsive video platform with subscriptions, moderated comments and real-time watch parties.'};
export default function RootLayout({children}:{children:React.ReactNode}) {return <html lang="en"><body>{children}</body></html>}
