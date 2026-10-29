package dev.sasha.sysuilocale;

import android.app.Activity;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public class MainActivity extends Activity {
    private TextView status;
    private Button button;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        int pad = (int) (getResources().getDisplayMetrics().widthPixels * 0.12f);

        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setGravity(Gravity.CENTER_HORIZONTAL);
        box.setPadding(pad, pad, pad, pad);

        button = new Button(this);
        button.setText("Применить en-US");
        button.setOnClickListener(v -> runFix());
        box.addView(button);

        status = new TextView(this);
        status.setTextSize(12);
        status.setGravity(Gravity.CENTER_HORIZONTAL);
        status.setText("Последний запуск:\n" + Fixer.last(this));
        box.addView(status);

        ScrollView scroll = new ScrollView(this);
        scroll.addView(box);
        setContentView(scroll);
    }

    private void runFix() {
        button.setEnabled(false);
        status.setText("Применяю…");
        new Thread(() -> {
            String r = Fixer.apply(this, "кнопка");
            runOnUiThread(() -> {
                status.setText(r);
                button.setEnabled(true);
            });
        }).start();
    }
}
