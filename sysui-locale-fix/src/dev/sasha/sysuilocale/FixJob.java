package dev.sasha.sysuilocale;

import android.app.job.JobParameters;
import android.app.job.JobService;

public class FixJob extends JobService {
    @Override
    public boolean onStartJob(JobParameters params) {
        new Thread(() -> {
            Fixer.apply(this, "загрузка");
            jobFinished(params, false);
        }).start();
        return true;
    }

    @Override
    public boolean onStopJob(JobParameters params) {
        return false;
    }
}
