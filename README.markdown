This is a simple [Sinatra][1] backed web-app to view groups on Flickr. It
doesn't do much beyond that. It's like Flickr River, only simpler/lamer. It
might be a good example of how to get going with Sinatra. [I'm also using
paging_keys.js written by hiddenloop.][2] There is some code in the repo I use
to run this on Dreamhost.

TODO:
 - Support URLs of the form: `gv.vqvz.com/group/<group url name>`, for example,
   `gv.vqvz.com/group/photographsonthebrain` rather than `gv.vqvz.com/group/755579@N24`
 - Expose fav's functionality

[1]: http://sinatrarb.com "Sinatra's website."
[2]: http://github.com/hiddenloop/paging_keys_js "paging_keys_js github page."
