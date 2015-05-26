all:
	livescript -cb index.ls
	sass index.sass index.css
	jade -P index.jade
