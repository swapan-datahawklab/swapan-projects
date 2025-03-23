package com.example.demo.commands;

import org.springframework.shell.command.annotation.Command;
import org.springframework.shell.command.annotation.Option;

@Command(command = "HelloCommand", group = "Hello Commands")
public class HelloCommand {

    @Command(command = "describe", description = "Describe XYZ that is passed")
    public String describe(@Option(longNames = {"xyz-arg"}, required = true) String xyzArg) {
        return "Hello world " + xyzArg;
    }

    @Command(command = "list", description = "List all foos")
    public String list() {
        return "Listy McListface";
    }
}