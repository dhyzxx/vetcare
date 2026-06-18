import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')! // Legacy or use Google Auth for HTTP v1

const supabase = createClient(supabaseUrl, supabaseServiceKey)

serve(async (req) => {
  try {
    // 1. Calculate tomorrow's date
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const targetDate = tomorrow.toISOString().split('T')[0]

    // 2. Fetch grooming schedules for tomorrow
    const { data: groomingData, error: groomingError } = await supabase
      .from('grooming_schedules')
      .select('id, user_id, pets(name)')
      .eq('tanggal', targetDate)
      .eq('is_done', false)

    if (groomingData && groomingData.length > 0) {
      for (const task of groomingData) {
        // Get user FCM token
        const { data: userData } = await supabase
          .from('user_profiles')
          .select('fcm_token')
          .eq('id', task.user_id)
          .single()

        if (userData?.fcm_token) {
          const title = "Grooming Reminder ✂️"
          const message = `Don't forget, ${task.pets.name} has a grooming schedule tomorrow!`
          
          // Send to FCM
          await sendFcmNotification(userData.fcm_token, title, message)
          
          // Log to notifications_log table
          await supabase.from('notifications_log').insert({
            user_id: task.user_id,
            judul: title,
            pesan: message,
            tipe: 'grooming',
            is_read: false
          })
        }
      }
    }

    // You can repeat the exact same logic above for 'vaccinations' table
    // by checking the 'jadwal_berikutnya' column.

    return new Response(JSON.stringify({ success: true, message: "Reminders sent" }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

// Helper function to send FCM
async function sendFcmNotification(token: string, title: string, body: string) {
  await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${fcmServerKey}`
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body }
    })
  })
}