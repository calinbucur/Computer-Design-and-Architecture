"""
This module represents the Producer.

Computer Systems Architecture Course
Assignment 1
March 2021
"""

# Calin-Andrei Bucur
# 332CB

from threading import Thread
import time

class Producer(Thread):
    """
    Class that represents a producer.
    """

    def __init__(self, products, marketplace, republish_wait_time, **kwargs):
        """
        Constructor.

        @type products: List()
        @param products: a list of products that the producer will produce

        @type marketplace: Marketplace
        @param marketplace: a reference to the marketplace

        @type republish_wait_time: Time
        @param republish_wait_time: the number of seconds that a producer must
        wait until the marketplace becomes available

        @type kwargs:
        @param kwargs: other arguments that are passed to the Thread's __init__()
        """

        # Call the thread constructor
        # Set this process as a daemon
        Thread.__init__(self, **kwargs)
        # Create the list of produced items
        # Transform the quantity into multiple items
        self.products = []
        for prod in products:
            for _ in range(prod[1]):
                self.products.append(prod)
        self.market = marketplace
        self.wait_time = republish_wait_time
        # Get an id for this producer
        self.prod_id = self.market.register_producer()

    def run(self):
        i = 0
        # Produce the first item
        time.sleep(self.products[0][2])
        while True:
            # Try publishing it
            res = self.market.publish(self.prod_id, self.products[i][0])
            # If succesful go to the next item and produce it
            if res:
                if i < len(self.products) - 1:
                    i += 1
                else:
                    i = 0
                time.sleep(self.products[i][2])
            # Wait a bit
            else:
                time.sleep(self.wait_time)
