"""
This module represents the Consumer.

Computer Systems Architecture Course
Assignment 1
March 2021
"""

# Calin-Andrei Bucur
# 332CB

from threading import Thread
import time

class Consumer(Thread):
    """
    Class that represents a consumer.
    """

    def __init__(self, carts, marketplace, retry_wait_time, **kwargs):
        """
        Constructor.

        :type carts: List
        :param carts: a list of add and remove actionerations

        :type marketplace: Marketplace
        :param marketplace: a reference to the marketplace

        :type retry_wait_time: Time
        :param retry_wait_time: the number of seconds that a producer must wait
        until the Marketplace becomes available

        :type kwargs:
        :param kwargs: other arguments that are passed to the Thread's __init__()
        """

        # Call the thread constructor
        Thread.__init__(self, **kwargs)
        self.market = marketplace
        # Initialize the carts and get ids for them
        self.carts = {}
        for cart in carts:
            self.carts[self.market.new_cart()] = cart
        self.wait_time = retry_wait_time

    def run(self):
        # Go through the carts
        for cart_id in self.carts:
            # Go through each action in the cart
            for action in self.carts[cart_id]:
                # Try doing the action until we do it the necessary number of times
                while action["quantity"] > 0:
                    flag = False
                    if action["type"] == "add":
                        flag = self.market.add_to_cart(cart_id, action["product"])
                    else:
                        flag = self.market.remove_from_cart(cart_id, action["product"])
                    if flag:
                        action["quantity"] -= 1
                    else:
                        time.sleep(self.wait_time)
            # Get the final order
            order = self.market.place_order(cart_id)
            # Print the bought items
            for item in order:
                print(self.name + " bought " + str(item))
