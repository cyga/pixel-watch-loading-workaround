package dev.sasha.sysuilocale;

import android.app.LocaleManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.LocaleList;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.Locale;

/**
 * Делает то же, что fix-watch-loading.sh: сбрасывает локаль Wear SystemUI и ставит en-US.
 * Сначала через LocaleManager (системный API, вызывается рефлексией),
 * если он недоступен — через "cmd locale" от имени приложения.
 * Оба пути требуют разрешения CHANGE_CONFIGURATION, выданного через adb.
 */
final class Fixer {
    static final String PKG = "com.google.android.wearable.sysui";
    static final String TARGET = "en-US";
    private static final String PREFS = "fixer";

    private Fixer() {}

    /** Блокирующий вызов: запускать не в главном потоке. */
    static String apply(Context ctx, String trigger) {
        StringBuilder log = new StringBuilder();
        String result;
        try {
            result = viaApi(ctx);
        } catch (Throwable t) {
            log.append("API: ").append(describe(t)).append('\n');
            try {
                result = viaCmd();
            } catch (Throwable t2) {
                result = "ОШИБКА: " + describe(t2);
            }
        }
        log.append(result);
        String stamp = new SimpleDateFormat("dd.MM HH:mm:ss", Locale.ROOT).format(new Date());
        String text = stamp + " (" + trigger + ")\n" + log;
        prefs(ctx).edit().putString("last", text).apply();
        return text;
    }

    static String last(Context ctx) {
        return prefs(ctx).getString("last", "ещё не запускалось");
    }

    private static SharedPreferences prefs(Context ctx) {
        return ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private static String viaApi(Context ctx) throws Exception {
        LocaleManager lm = ctx.getSystemService(LocaleManager.class);
        Method set = LocaleManager.class.getMethod("setApplicationLocales", String.class, LocaleList.class);
        invoke(set, lm, PKG, LocaleList.getEmptyLocaleList());
        Thread.sleep(2000);
        invoke(set, lm, PKG, LocaleList.forLanguageTags(TARGET));
        // Прочитать обратно нельзя: getApplicationLocales для чужого пакета требует
        // READ_APP_SPECIFIC_LOCALES (signature|installer), его через adb не выдать.
        return "OK: записано " + TARGET;
    }

    private static String viaCmd() throws Exception {
        String r1 = run("cmd", "locale", "set-app-locales", PKG, "--locales", "");
        Thread.sleep(2000);
        String r2 = run("cmd", "locale", "set-app-locales", PKG, "--locales", TARGET);
        String now = run("cmd", "locale", "get-app-locales", PKG);
        return "через cmd: " + (r1 + " " + r2).trim() + "\n" + now.trim();
    }

    private static String run(String... args) throws Exception {
        Process p = new ProcessBuilder(Arrays.asList(args)).redirectErrorStream(true).start();
        String out = read(p.getInputStream());
        int code = p.waitFor();
        if (code != 0) throw new IllegalStateException("exit " + code + ": " + out.trim());
        return out;
    }

    private static Object invoke(Method m, Object target, Object... args) throws Exception {
        try {
            return m.invoke(target, args);
        } catch (InvocationTargetException e) {
            Throwable c = e.getCause();
            if (c instanceof Exception) throw (Exception) c;
            throw e;
        }
    }

    private static String read(InputStream in) throws Exception {
        ByteArrayOutputStream bo = new ByteArrayOutputStream();
        byte[] buf = new byte[4096];
        int n;
        while ((n = in.read(buf)) > 0) bo.write(buf, 0, n);
        return bo.toString("UTF-8");
    }

    private static String describe(Throwable t) {
        String hint = "";
        if (t instanceof SecurityException) {
            hint = "\n→ нет разрешения: adb shell pm grant dev.sasha.sysuilocale android.permission.CHANGE_CONFIGURATION";
        }
        return t.getClass().getSimpleName() + ": " + t.getMessage() + hint;
    }
}
