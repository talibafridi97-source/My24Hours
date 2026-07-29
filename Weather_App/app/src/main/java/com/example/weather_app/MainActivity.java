package com.example.weather_app;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

import org.json.JSONObject;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class MainActivity extends AppCompatActivity {

    TextView cityTxt, tempTxt, conditionTxt;
    String API_KEY = "2959cba1ec2ef3bae64ea02f22a56946"; // Your API key
    OkHttpClient client = new OkHttpClient();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        cityTxt = findViewById(R.id.cityTxt);
        tempTxt = findViewById(R.id.tempTxt);
        conditionTxt = findViewById(R.id.conditionTxt);

        fetchWeather("Kohat");
    }

    void fetchWeather(String cityName) {
        String url = "https://api.openweathermap.org/data/2.5/weather?q="
                + cityName + "&units=metric&appid=" + API_KEY;

        Request request = new Request.Builder().url(url).build();

        client.newCall(request).enqueue(new Callback() {

            @Override
            public void onFailure(Call call, IOException e) {
                runOnUiThread(() -> {
                    cityTxt.setText("Error");
                    tempTxt.setText("--");
                    conditionTxt.setText("Failed to load");
                });
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {

                if (!response.isSuccessful()) {
                    runOnUiThread(() -> {
                        cityTxt.setText("City Not Found");
                        tempTxt.setText("--");
                        conditionTxt.setText("--");
                    });
                    return;
                }

                try {
                    String jsonData = response.body().string();
                    Log.d("WeatherResponse", jsonData);

                    JSONObject obj = new JSONObject(jsonData);

                    String city = obj.optString("name", "Unknown");
                    String temp = obj.getJSONObject("main").optString("temp", "--");
                    String condition = obj.getJSONArray("weather")
                            .getJSONObject(0).optString("main", "--");

                    runOnUiThread(() -> {
                        cityTxt.setText(city);
                        tempTxt.setText(temp + "°C");
                        conditionTxt.setText(condition);
                    });

                } catch (Exception ex) {
                    runOnUiThread(() -> {
                        cityTxt.setText("Error");
                        tempTxt.setText("--");
                        conditionTxt.setText("No Data");
                    });
                }
            }
        });
    }
}
