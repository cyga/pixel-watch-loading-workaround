package dev.sasha.sysuilocale;

import android.app.job.JobInfo;
import android.app.job.JobScheduler;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

/** После загрузки ставит задачу на ~20 с позже, чтобы SystemUI успел подняться. */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context ctx, Intent intent) {
        if (!Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) return;
        JobInfo job = new JobInfo.Builder(1, new ComponentName(ctx, FixJob.class))
                .setMinimumLatency(20_000)
                .setOverrideDeadline(60_000)
                .build();
        ctx.getSystemService(JobScheduler.class).schedule(job);
    }
}
