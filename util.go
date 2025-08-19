package main

import (
	"fmt"
	"io"
	"os"
)

func must(err error) {
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "ERROR: %s", err.Error())
	}
}

func fprintf(w io.Writer, format string, args ...any) {
	_, _ = fmt.Fprintf(w, format, args...)
}

func fprintln(w io.Writer, args ...any) {
	_, _ = fmt.Fprintln(w, args...)
}
