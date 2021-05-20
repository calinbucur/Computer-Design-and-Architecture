ASC
Tema 1
Calin-Andrei Bucur
332CB

I'll go through this class by class

Product:

It is mostly unmodified
I just added the __eq__ method in order to be able to compare products

Marketplace:

In the constructor I create an empty list where the carts (lists as well) will be stored
I also create an empty buffer where each producer's list will be stored and a list of locks, one for each queue.
I need these locks to make sure only one thread adds/removes something from the queue at a time
I also initialize the producer and cart ids with -1 and assign the next number to the producer/cart it's needed for
I also have a lock for each id type to make sure an id isn't assigned simultanously to two producers

register_producer increments the id and returns it
also it adds the producer's queue and lock

new_cart does the same but for carts

publish checks if there's space in the producer's queue and adds the product

add_to_cart looks for the product through each producer's queue
if it's found it removes it, adds it to the cart together with the producer id (in case of removal) and returns True

remove_from_cart finds the product in the cart, removes it and adds it back into the producer's queue

place_order simply adds all the items from the cart to alist and returns it

Producer:

in the run method
first it sleeps (produces the first item)
goes through the items over and over in an infinite loop
tries to publish the item
if succesful goes to the next item, sleeps to produce it

Consumer:

in the run method
goes through each action in each cart
tries doing it until it succeds
each time reduces the number of times the action needs to be done
when a cart is done calls place_order then prints the result

That's pretty much it
A nice and easy homework
Unfortunately I didn't use git because I did it in one sitting (2 hours). Csf n-ai csf :)))