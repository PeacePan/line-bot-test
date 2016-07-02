package com.peacepan.line;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import jp.line.android.sdk.*;
import jp.line.android.sdk.login.*;
import jp.line.android.sdk.model.*;
import jp.line.android.sdk.exception.*;
import jp.line.android.sdk.api.*;

public class LineConnect extends CordovaPlugin {
    // Debugging
    private static final String TAG = "LineConnect";

    private static final String ACTION_LOGIN = "login";
    private static final String ACTION_LOGOUT = "logout";
    private static final String ACTION_GET_PROFILE = "getUserProfile";

    private Activity activity;
    private Context context;

    private LineSdkContext sdkContext;
    private LineAuthManager authManager;
    private ApiClient apiClient;

    @Override
    public boolean execute(final String action, final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "action = " + action);

        if (activity == null) {
            // init line SDK
            activity = cordova.getActivity();
            context = activity.getApplicationContext();

            LineSdkContextManager.initialize(context);
            sdkContext = LineSdkContextManager.getSdkContext();
            authManager = sdkContext.getAuthManager();
            apiClient = sdkContext.getApiClient();

            Log.d(TAG, "Line SDK Initialized.");
            Log.d(TAG, "ChannelId = " + sdkContext.getChannelId());
            Log.d(TAG, "SdkVersion = " + sdkContext.getSdkVersion());
        }

        activity.runOnUiThread(new Runnable() {
            public void run() {
              if (action.equals(ACTION_LOGIN)) {
                lineLogin(callbackContext);
              } else if (action.equals(ACTION_LOGOUT)) {
                lineLogout(callbackContext);
              } else if (action.equals(ACTION_GET_PROFILE)) {
                getUserProfile(callbackContext);
              } else { // Error
                  callbackContext.error("Invalid action: " + action);
              }
            }
        });
        return true;
    }

    private void lineLogin(final CallbackContext callbackContext) {
      Log.d(TAG, "Run Line SDK login");

      LineLoginFuture loginFuture = authManager.login(activity);

      loginFuture.addFutureListener(new LineLoginFutureListener() {
          @Override
          public void loginComplete(LineLoginFuture future) {
              Log.d(TAG, "login progress: " + future.getProgress());

              switch(future.getProgress()) {
                  case SUCCESS: // Login successfully
                      try {
                          AccessToken token = future.getAccessToken();
                          JSONObject json = new JSONObject();
                          json.put("mid", token.mid);
                          json.put("accessToken", token.accessToken);
                          json.put("expire", token.expire);
                          json.put("refreshToken", token.refreshToken);
                          callbackContext.success(json);
                      } catch (JSONException e) {
                          callbackContext.error("JSON parse error, reason: " + e.toString());
                      }
                      callbackContext.success();
                      break;
                  case CANCELED: // Login canceled by user
                      callbackContext.error("Login Canceled");
                      break;
                  default: // Error
                      Throwable cause = future.getCause();
                      String reason = "";
                      if (cause instanceof LineSdkLoginException) {
                          LineSdkLoginException loginException = (LineSdkLoginException)cause;
                          LineSdkLoginError error = loginException.error;
                          switch(error) {
                              case FAILED_START_LOGIN_ACTIVITY:
                                  reason = "Failed launching LINE application or WebLoginActivity (Activity may be null)";
                                  break;
                              case FAILED_A2A_LOGIN:
                                  reason = "Failed LINE login";
                                  break;
                              case FAILED_WEB_LOGIN:
                                  reason = "Failed Web login";
                                  break;
                              case UNKNOWN:
                                  reason = "Un expected error occurred";
                                  break;
                          }
                      } else {
                          reason = "Other exceptions";
                      }
                      callbackContext.error(reason);
                      break;
              }
          }
      });
    }

    private void lineLogout(final CallbackContext callbackContext) {

    }

    private void getUserProfile(final CallbackContext callbackContext) {
        Log.d(TAG, "Run Line SDK getUserProfile");
        apiClient.getMyProfile(new ApiRequestFutureListener<Profile>() {
            @Override
            public void requestComplete(ApiRequestFuture future) {
                switch(future.getStatus()) {
                    case SUCCESS:
                        Profile profile = (Profile)future.getResponseObject();
                        try {
                            JSONObject json = new JSONObject();
                            json.put("displayName", profile.displayName);
                            json.put("mid", profile.mid);
                            json.put("pictureUrl", profile.pictureUrl);
                            json.put("statusMessage", profile.statusMessage);
                            callbackContext.success(json);
                        } catch (JSONException e) {
                            callbackContext.error("JSON parse error, reason: " + e.toString());
                        }
                        break;
                    case FAILED:
                    default:
                        Throwable cause = future.getCause();
                        callbackContext.error("getUserProfile: " + cause);
                        break;
                }
            }
        });
    }
}
