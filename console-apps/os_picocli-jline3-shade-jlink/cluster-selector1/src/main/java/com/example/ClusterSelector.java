package com.example;

import com.example.model.Cluster;
import com.example.service.ClusterConnector;
import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import org.jline.reader.LineReader;
import org.jline.reader.LineReaderBuilder;

import java.io.InputStream;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

@Command(name = "cluster-selector", mixinStandardHelpOptions = true, version = "1.2", description = "Interactive CLI to select OpenShift clusters from YAML file")
public class ClusterSelector implements Callable<Integer> {
    @Option(names = {"-u", "--username"}, description = "Username")
    private String username;

    @Option(names = {"-e", "--env"}, description = "Environment (prod/non-prod)")
    private String env;

    public static void main(String[] args) {
        System.exit(new CommandLine(new ClusterSelector()).execute(args));
    }

    @Override
    public Integer call() throws Exception {
        LineReader reader = LineReaderBuilder.builder().build();
        if (username == null) username = reader.readLine("Enter username: ");
        if (env == null) env = reader.readLine("Select environment (prod/non-prod): ");

        ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
        InputStream is = getClass().getClassLoader().getResourceAsStream("clusterinfo.yaml");
        Map<String, List<Cluster>> data = mapper.readValue(is, new TypeReference<Map<String, List<Cluster>>>() {});
        List<Cluster> clusters = data.get("clusters");

        List<Cluster> filtered = clusters.stream()
            .filter(c -> c.env.equalsIgnoreCase(env))
            .collect(Collectors.toList());

        System.out.println("Available clusters:");
        for (int i = 0; i < filtered.size(); i++) {
            System.out.printf("%d) %s (%s)%n", i + 1, filtered.get(i).name, filtered.get(i).context);
        }

        String input = reader.readLine("Select clusters by numbers (comma-separated) or 'all': ");
        List<Cluster> selected = "all".equalsIgnoreCase(input.trim()) ? filtered : Arrays.stream(input.split(","))
            .map(String::trim).map(Integer::parseInt).map(idx -> filtered.get(idx - 1)).collect(Collectors.toList());

        System.out.println("Selected clusters:");
        selected.forEach(c -> System.out.printf("- %s%n", c.name));

        ClusterConnector connector = new ClusterConnector();
        for (Cluster c : selected) {
            connector.connect(c);
        }
        return 0;
    }
}
