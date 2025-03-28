package clidemo.cli.commands;

import clidemo.cli.common.HelpOption;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;

@Command(name = "list", description = "Lists all created values")
public class ListCommand implements Runnable {

    private Logger logger = LoggerFactory.getLogger(ListCommand.class);

    @Mixin
    private HelpOption helpOption;

    @Override
    public void run() {
        logger.info("Executing list command");
    }
}
