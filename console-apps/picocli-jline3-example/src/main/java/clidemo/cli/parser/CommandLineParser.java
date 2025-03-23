package clidemo.cli.parser;

import clidemo.cli.commands.CreateCommand;
import clidemo.cli.commands.DeleteCommand;
import clidemo.cli.commands.ListCommand;
import clidemo.cli.commands.UpdateCommand;
import clidemo.cli.common.HelpOption;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;

import static picocli.CommandLine.Option;

@Command(
        subcommands = {CreateCommand.class, ListCommand.class, UpdateCommand.class, DeleteCommand.class},
        versionProvider = VersionProvider.class
)
public class CommandLineParser {

    @Mixin
    private HelpOption helpOption;
    @Option(names = {"-v", "--version"}, versionHelp = true, description = "Print version information and exit.")
    private boolean versionHelpRequested;
}
