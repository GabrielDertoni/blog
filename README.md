# My Personal Blog

## Description and goals

This blog has simplicity and portability in mind. It should be easy to use the
same content source (written in markdown) to generate output in many formats
such as `HTML` or `PDF`. In order to build the blog pages simply run `make html`
and all pages should be build under `public/` and are ready to be served by a
web server.

To run the blog in `localhost` using a simple python server, just run `make serve`.

## Future work

It should also be possible and easy to export the blog in `PDF` format. However,
right now this is not implemented in the `Makefile`.

## References

- [Code highlighting style](https://github.com/tajmone/pandoc-goodies/tree/master/skylighting/themes)
- [Pandoc](https://pandoc.org/)
