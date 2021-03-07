#######################
Run-Stuff Emacs Package
#######################

A package to conveniently execute command-line actions from Emacs.

Available via `melpa <https://melpa.org/#/run-stuff>`__.


Motivation
==========

Not every command makes sense to alias or wrap in a shell script,
sometimes there are tasks you run every so often or paths you might want to go back to later on.

This makes it possible to use a file *(org-mode or just a text file)*
as a convenient ad-hoc reference for miscellaneous commands and files
*(a step up from hoping that handy command remains in you're shells search history)*.


Usage
=====

This package provides ``run-stuff-command-on-region-or-line`` which can be called
from a key binding to execute the current selection or line.

Since this has the potential to do some damage, its suggested you use a shortcut you wont press by accident.
eg: ``Ctrl-Alt-Shift-Return``.

Example use in ``init.el``::

  (global-set-key (kbd "<C-M-S-return>") 'run-stuff-command-on-region-or-line)


While you don't have to use/know all of the following prefixes,
these can be used to control how execution is performed.

- ``$`` Run in terminal.
- ``@`` Open in an Emacs buffer.
- ``~`` Open with default mime type (works for paths too).
- ``http://`` or ``https://`` opens in a web-browser.
- Directories are opened in the terminal.
- Otherwise default to running the command without a terminal
  when none of the conditions above succeed.

For longer commands you may want to split them over multiple lines.
This is supported using a trailing backslash ``\``,
the cursor may be anywhere within the text, the upper and lower lines will be detected.

Examples::

  # A quick test to see everything works.
  $ find /

  # Opens a text file.
  ~ /path/to/my/project.txt

  # Opens a web site.
  http://wiki.blender.org

  # Edit your Emacs config.
  @ ~/.config/emacs/init.el

  # Play a movie from where you left off.
  mpv '/path/to/movie.mp4' --no-terminal \
  --start=+0:30:00

  # Play the 10 latest podcasts.
  $ eval audacious \
      $(find ~/gPodder/Downloads -type f -printf "%T+\t%p\n" \
      -name "*.mp*" -o -name "*.og*" -o -name "*.ac3" | \
      sort -r | head -n 10 | cut -f2 -d$'\t' | xargs -d '\n' printf " %q ") & disown


If you'd like to change the default terminal from xterm, it can be configured as follows::

   (setq run-stuff-terminal-command "gnome-terminal")
   (setq run-stuff-terminal-execute-arg "--command")


Customization
-------------

``run-stuff-open-command`` (``xdg-open``)
   The command used to open with the default mime type.
``run-stuff-terminal-command`` (``xterm``)
   The command to use when opening a terminal.
``run-stuff-terminal-execute-arg`` (``-e``)
   The terminal argument to use for running a command.
``run-stuff-handlers``
   Used to customize pattern matching and to add your own handlers.

   This contains a list of callbacks that execute in-order to handle running something in the current context.

   First (extract function)
     Return a string from the current context (typically the current line).
   Second (handle function)
     Take the result of the extract function and run the function if it matches or return nil.

   The handlers are handled in order, first to last.
   On success, no other handlers are tested.

   This can be made a buffer local variable to customize this for each mode.
