"""
This module represents the Marketplace.

Computer Systems Architecture Course
Assignment 1
March 2021
"""

# Calin-Andrei Bucur
# 332CB
from threading import Lock

class Marketplace:
    """
    Class that represents the Marketplace. It's the central part of the implementation.
    The producers and consumers use its methods concurrently.
    """
    def __init__(self, queue_size_per_producer):
        """
        Constructor

        :type queue_size_per_producer: Int
        :param queue_size_per_producer: the maximum size of a queue associated with each producer
        """
        self.carts = [] # stores all the carts
        self.prod_id = -1 # used for assigning producer ids
        self.cart_id = -1 # used for assigning cart ids
        self.queue_size = queue_size_per_producer
        # locks that guarantee the correct assignment of ids
        self.prod_id_lock = Lock()
        self.cart_id_lock = Lock()
        self.buff = [] # stores all the published products
        self.locks = [] # a lock for each producer

    def register_producer(self):
        """
        Returns an id for the producer that calls this.
        """
        # Assigns the next available id
        # Adds the producer's queue to the buffer
        # Creates the producer's lock
        with self.prod_id_lock:
            self.prod_id += 1
            self.buff.append([])
            self.locks.append(Lock())
            return self.prod_id

    def publish(self, producer_id, product):
        """
        Adds the product provided by the producer to the marketplace

        :type producer_id: String
        :param producer_id: producer id

        :type product: Product
        :param product: the Product that will be published in the Marketplace

        :returns True or False. If the caller receives False, it should wait and then try again.
        """
        with self.locks[producer_id]:
            # Checks if there is free space in the queue
            if len(self.buff[producer_id]) >= self.queue_size:
                return False
            self.buff[producer_id].append(product)
            return True

    def new_cart(self):
        """
        Creates a new cart for the consumer

        :returns an int representing the cart_id
        """
        # Assigns the next available id
        # Adds an empty cart to the list of carts
        with self.cart_id_lock:
            self.carts.append([])
            self.cart_id += 1
            return self.cart_id

    def add_to_cart(self, cart_id, product):
        """
        Adds a product to the given cart. The method returns

        :type cart_id: Int
        :param cart_id: id cart

        :type product: Product
        :param product: the product to add to cart

        :returns True or False. If the caller receives False, it should wait and then try again
        """
        # Go through each producer
        for i in range(len(self.buff)):
            with self.locks[i]:
                # Go through his queue
                for prod in self.buff[i]:
                    # If the product is found take it
                    # Add it to the cart
                    # Also keep the id of the producer in case we want to return it
                    if product.__eq__(prod):
                        self.carts[cart_id].append((prod, i))
                        self.buff[i].remove(prod)
                        return True
        return False

    def remove_from_cart(self, cart_id, product):
        """
        Removes a product from cart.

        :type cart_id: Int
        :param cart_id: id cart

        :type product: Product
        :param product: the product to remove from cart
        """

        # Go through the items in the cart
        for prod in self.carts[cart_id]:
            # Remove the item and add it back to the producer's queue
            if product.__eq__(prod[0]):
                with self.locks[prod[1]]:
                    self.buff[prod[1]].append(prod[0])
                self.carts[cart_id].remove(prod)
                return True
        return False

    def place_order(self, cart_id):
        """
        Return a list with all the products in the cart.

        :type cart_id: Int
        :param cart_id: id cart
        """
        # Add the items from the cart to a list and return it
        order = []
        for prod, _ in self.carts[cart_id]:
            order.append(prod)
        return order
