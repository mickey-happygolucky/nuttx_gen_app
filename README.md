# nuttx_gen_app.sh

NuttX application template generator script.

# Usage

First, copy `nuttx_gen_app.sh` to any directory in the PATH environtment variable.
Next, Type commands as follows. 

```txt
$ export NUTTX_APP_DIR=</path/to/apps>
$ nuttx_gen_app.sh APP_NAME [(STACK_SIZE|-d)]
```

* APP_NAME : name of application that will be create.
* STACK_SIZE(optional) : default stack size of application.
* -d(optional) : delete application which specified by APP_NAME.


NUTTX_APP_DIR should be set path for `apps` directory.
`apps` directory is clone of repository for NuttX applications.

