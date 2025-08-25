package io.github.stringmanolo.selfcontrol;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.graphics.Color;
import android.graphics.Path;
import android.os.Build;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;

public class MouseAccessibilityService extends AccessibilityService {

    private WindowManager windowManager;
    private TextView logTextView;
    private ScrollView scrollView;
    private TextView closeButton;

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) { }

    @Override
    public void onInterrupt() {
        log("Servicio interrumpido");
    }

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        setupOverlay();
        log("AccessibilityService conectado");

        new Thread(new Runnable() {
            @Override
            public void run() {
                log("Iniciando TCPServer");
                new TCPServer().run();
            }
        }).start();
    }

    // Gestos
    public void performTap(float x, float y) {
        log("Tap en: " + x + "," + y);
        showTapIndicator(x, y);
        Path path = new Path();
        path.moveTo(x, y);
        GestureDescription.StrokeDescription stroke = new GestureDescription.StrokeDescription(path, 0, 50);
        GestureDescription gesture = new GestureDescription.Builder().addStroke(stroke).build();
        dispatchGesture(gesture, null, null);
    }

    public void performSwipe(float x1, float y1, float x2, float y2, long duration) {
        log("Swipe de: " + x1 + "," + y1 + " a " + x2 + "," + y2);
        Path path = new Path();
        path.moveTo(x1, y1);
        path.lineTo(x2, y2);
        GestureDescription.StrokeDescription stroke = new GestureDescription.StrokeDescription(path, 0, duration);
        GestureDescription gesture = new GestureDescription.Builder().addStroke(stroke).build();
        dispatchGesture(gesture, null, null);
    }

    public void performGlobal(int action) {
        log("Global action: " + action);
        performGlobalAction(action);
    }

    // Overlay click-through con logs y botón cerrar
    private void setupOverlay() {
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);

        scrollView = new ScrollView(this);
        logTextView = new TextView(this);
        logTextView.setTextColor(Color.WHITE);
        logTextView.setTextSize(14);
        logTextView.setBackgroundColor(Color.argb(150, 0, 0, 0));
        logTextView.setPadding(10, 10, 10, 10);

        scrollView.addView(logTextView);

        WindowManager.LayoutParams logParams;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            logParams = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE |
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    android.graphics.PixelFormat.TRANSLUCENT);
        } else {
            logParams = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_PHONE,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE |
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    android.graphics.PixelFormat.TRANSLUCENT);
        }
        logParams.gravity = Gravity.TOP;
        windowManager.addView(scrollView, logParams);

        // Botón flotante para cerrar overlay
        closeButton = new TextView(this);
        closeButton.setText("X");
        closeButton.setTextColor(Color.WHITE);
        closeButton.setBackgroundColor(Color.argb(200, 255, 0, 0));
        closeButton.setTextSize(18);
        closeButton.setPadding(10, 10, 10, 10);

        WindowManager.LayoutParams btnParams;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            btnParams = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                    android.graphics.PixelFormat.TRANSLUCENT);
        } else {
            btnParams = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_PHONE,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                    android.graphics.PixelFormat.TRANSLUCENT);
        }
        btnParams.gravity = Gravity.TOP | Gravity.END;
        btnParams.x = 10;
        btnParams.y = 10;

        closeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                removeOverlay();
            }
        });

        windowManager.addView(closeButton, btnParams);
    }

    // Mostrar logs en overlay
    private void log(final String message) {
        if (logTextView != null) {
            logTextView.post(new Runnable() {
                @Override
                public void run() {
                    logTextView.append(message + "\n");
                    scrollView.post(new Runnable() {
                        @Override
                        public void run() {
                            scrollView.fullScroll(ScrollView.FOCUS_DOWN);
                        }
                    });
                }
            });
        }
    }

    // Mostrar indicador visual de tap
    private void showTapIndicator(final float x, final float y) {
        if (windowManager == null) return;

        final TextView tapView = new TextView(this);
        tapView.setBackgroundColor(Color.argb(200, 255, 0, 0)); // rojo
        tapView.setWidth(50);
        tapView.setHeight(50);

        WindowManager.LayoutParams params;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            params = new WindowManager.LayoutParams(
                    50,
                    50,
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                    android.graphics.PixelFormat.TRANSLUCENT);
        } else {
            params = new WindowManager.LayoutParams(
                    50,
                    50,
                    WindowManager.LayoutParams.TYPE_PHONE,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                    android.graphics.PixelFormat.TRANSLUCENT);
        }

        params.x = (int) x - 25;
        params.y = (int) y - 25;
        params.gravity = Gravity.TOP | Gravity.START;

        windowManager.addView(tapView, params);

        tapView.postDelayed(new Runnable() {
            @Override
            public void run() {
                try {
                    windowManager.removeView(tapView);
                } catch (Exception e) { }
            }
        }, 500);
    }

    // Remover overlay y botón
    private void removeOverlay() {
        try {
            if (scrollView != null) windowManager.removeView(scrollView);
            if (closeButton != null) windowManager.removeView(closeButton);
            scrollView = null;
            logTextView = null;
            closeButton = null;
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // TCPServer multicliente
    class TCPServer implements Runnable {
        @Override
        public void run() {
            try {
                log("Intentando abrir ServerSocket en puerto 5000");
                ServerSocket server = new ServerSocket(5000);
                log("ServerSocket abierto, esperando clientes...");

                while (true) {
                    final Socket client = server.accept();
                    log("Cliente conectado: " + client.getInetAddress());

                    new Thread(new Runnable() {
                        @Override
                        public void run() {
                            try {
                                BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
                                String line;
                                while ((line = in.readLine()) != null) {
                                    line = line.trim();
                                    log("Comando recibido: " + line);
                                    handleCommand(line);
                                }
                            } catch (Exception e) {
                                log("Cliente desconectado o error: " + e.getMessage());
                            } finally {
                                try { client.close(); } catch (Exception ex) {}
                            }
                        }
                    }).start();
                }

            } catch (Exception e) {
                log("Error en TCPServer: " + e.getMessage());
                e.printStackTrace();
            }
        }

        private void handleCommand(String line) {
            try {
                if (line.contains("\"action\":\"tap\"")) {
                    int x = Integer.parseInt(line.split("\"x\":")[1].split(",")[0]);
                    int y = Integer.parseInt(line.split("\"y\":")[1].replace("}", ""));
                    performTap(x, y);
                } else if (line.contains("\"action\":\"swipe\"")) {
                    String[] parts = line.replace("{", "").replace("}", "").split(",");
                    float x1 = Float.parseFloat(parts[1].split(":")[1]);
                    float y1 = Float.parseFloat(parts[2].split(":")[1]);
                    float x2 = Float.parseFloat(parts[3].split(":")[1]);
                    float y2 = Float.parseFloat(parts[4].split(":")[1]);
                    long dur = Long.parseLong(parts[5].split(":")[1]);
                    performSwipe(x1, y1, x2, y2, dur);
                } else if (line.contains("\"action\":\"home\"")) {
                    performGlobal(GLOBAL_ACTION_HOME);
                } else if (line.contains("\"action\":\"back\"")) {
                    performGlobal(GLOBAL_ACTION_BACK);
                } else {
                    log("Comando no reconocido: " + line);
                }
            } catch (Exception e) {
                log("Error al manejar comando: " + e.getMessage());
            }
        }
    }
}