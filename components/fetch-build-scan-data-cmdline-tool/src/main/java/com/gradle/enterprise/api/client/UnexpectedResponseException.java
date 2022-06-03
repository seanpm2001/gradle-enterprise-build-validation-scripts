package com.gradle.enterprise.api.client;

import okhttp3.Request;
import okhttp3.Response;

import java.net.URL;

public class UnexpectedResponseException extends FailedRequestException {
    public UnexpectedResponseException(String buildScanId, URL gradleEnterpriseServer, String responseBody) {
        super(String.format("Encountered an unexpected response while fetching build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)),
            responseBody);
    }
}
