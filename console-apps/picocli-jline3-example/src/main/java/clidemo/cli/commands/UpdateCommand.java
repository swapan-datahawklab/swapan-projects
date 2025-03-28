package clidemo.cli.commands;

import clidemo.cli.common.HelpOption;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

@Command(name = "update", description = "Updates value based on id")
public class UpdateCommand implements Runnable {

    private Logger logger = LoggerFactory.getLogger(UpdateCommand.class);

    @Mixin
    private HelpOption helpOption;

    @Option(names = "-id", description = "value id", required = true)
    private String id;
    @Option(names = "-name", description = "value name")
    private String name;
    @Option(names = "-value", description = "value content", required = true)
    private String value;

    @Override
    public void run() {
        logger.info("Executing update command with id = " + id + ", name = " + name + ", value = " + value);
    }
}
