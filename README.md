# TestBox CLI

```
████████╗███████╗███████╗████████╗██████╗  ██████╗ ██╗  ██╗      ██████╗██╗     ██╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗╚██╗██╔╝     ██╔════╝██║     ██║
   ██║   █████╗  ███████╗   ██║   ██████╔╝██║   ██║ ╚███╔╝█████╗██║     ██║     ██║
   ██║   ██╔══╝  ╚════██║   ██║   ██╔══██╗██║   ██║ ██╔██╗╚════╝██║     ██║     ██║
   ██║   ███████╗███████║   ██║   ██████╔╝╚██████╔╝██╔╝ ██╗     ╚██████╗███████╗██║
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝      ╚═════╝╚══════╝╚═╝
```

This is the official TestBox CLI for CommandBox.  It is a collection of commands to help you work with TestBox and its ecosystem.

## License

Apache License, Version 2.0.

## TestBox CLI Versions

The CLI also matches the major version of TestBox.

## System Requirements

- CommandBox 5.5+

## Installation

Install the commands via CommandBox like so:

```bash
box install testbox-cli
```

## Usage

You can use the CLI for many things like generating tests, harnesses, running tests and more.  Please remember that you can always get help on any command by using the `--help` flag.

## BoxLang Generation Support

The CLI will try to detect if you are running a BoxLang server or are in a BoxLang project using the following discovery techniques in order to determine if the command generators should use the BoxLang language or CFML.

- Is the server running in the current directory a BoxLang server
- Do you have a `testbox.runner=boxlang` in your `box.json` file
- Do you have the `language=boxlang` in your `box.json` file

## CFML Generation Support

The CLI will try to detect if you are running a CFML server or are in a CFML project using the following discovery techniques in order to determine if the command generators should use the CFML language or BoxLang.

- Is the server running in the current directory a CFML (Lucee or Adobe) server
- Do you have a `language=cfml` in your `box.json` file

----

## Credits & Contributions

I THANK GOD FOR HIS WISDOM IN THIS PROJECT

### The Daily Bread

"I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
