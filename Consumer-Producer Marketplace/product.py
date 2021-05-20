"""
This module offers the available Products.

Computer Systems Architecture Course
Assignment 1
March 2021
"""

# Calin-Andrei Bucur
# 332CB

from dataclasses import dataclass

@dataclass(init=True, repr=True, order=False, frozen=True)
class Product:
    """
    Class that represents a product.
    """
    name: str
    price: int

    # Method for comparing two products
    def __eq__(self, product):
        pass


@dataclass(init=True, repr=True, order=False, frozen=True)
class Tea(Product):
    """
    Tea products
    """
    type: str

    def __eq__(self, product):
        return (isinstance(product, Tea) and
                self.name == product.name and
                self.price == product.price and
                self.type == product.type)


@dataclass(init=True, repr=True, order=False, frozen=True)
class Coffee(Product):
    """
    Coffee products
    """
    acidity: str
    roast_level: str

    def __eq__(self, product):
        return (isinstance(product, Coffee) and
                self.name == product.name and
                self.price == product.price and
                self.acidity == product.acidity and
                self.roast_level == product.roast_level)
