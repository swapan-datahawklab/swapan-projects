package clidemo.cli.commands;

import clidemo.cli.common.HelpOption;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

@Command(name = "delete", description = "Deletes value by id")
public class DeleteCommand implements Runnable {

    private Logger logger = LoggerFactory.getLogger(DeleteCommand.class);

    @Mixin
    private HelpOption helpOption;

    @Option(names = "-id", description = "value id to delete", required = true)
    private String id;

    @Override
    public void run() {
        logger.info("Executing delete command with id = " + id);
    }
}
