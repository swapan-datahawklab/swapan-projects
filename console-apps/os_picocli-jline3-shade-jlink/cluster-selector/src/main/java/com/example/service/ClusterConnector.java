package com.example.service;

import com.example.model.Cluster;
import io.fabric8.kubernetes.client.Config;
import io.fabric8.kubernetes.client.ConfigBuilder;
import io.fabric8.openshift.client.DefaultOpenShiftClient;
import io.fabric8.openshift.client.OpenShiftClient;

public class ClusterConnector {
    public void connect(Cluster cluster) {
        Config config = new ConfigBuilder()
                .withMasterUrl(cluster.url)
                .withNamespace(cluster.context)
                .build();
        try (OpenShiftClient client = new DefaultOpenShiftClient(config)) {
            System.out.printf("Connected to %s: version=%s%n", cluster.context, client.getVersion().getGitVersion());
        } catch (Exception e) {
            System.err.printf("Failed to connect to %s: %s%n", cluster.context, e.getMessage());
        }
    }
}
