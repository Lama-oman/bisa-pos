import 'package:flutter/material.dart';

void main() {
  runApp(const BisaPOS());
}

class BisaPOS extends StatelessWidget {
  const BisaPOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bisa POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const PosHomePage(),
    );
  }
}

class Ingredient {
  final String name;
  double stock;
  final String unit;
  double purchasePrice; // Price per unit when bought
  double totalCost; // Total cost of current stock

  Ingredient({
    required this.name, 
    required this.stock, 
    required this.unit,
    this.purchasePrice = 0.0,
    this.totalCost = 0.0,
  });
}

class RecipeItem {
  String ingredientName;
  double amount;

  RecipeItem({required this.ingredientName, required this.amount});
}

class Product {
  String name;
  double price;
  String category;
  final List<RecipeItem> recipe;

  Product({required this.name, required this.price, required this.category, required this.recipe});

  bool canMake(Map<String, Ingredient> inventory) {
    for (var item in recipe) {
      final ingredient = inventory[item.ingredientName];
      if (ingredient == null || ingredient.stock < item.amount) {
        return false;
      }
    }
    return true;
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class SaleRecord {
  final DateTime date;
  final List<CartItem> items;
  final double total;

  SaleRecord({required this.date, required this.items, required this.total});
}

class ExpenseRecord {
  final String description;
  final double amount;
  final DateTime date;

  ExpenseRecord({required this.description, required this.amount, required this.date});
}

class PosHomePage extends StatefulWidget {
  const PosHomePage({super.key});

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  final Map<String, Ingredient> _inventory = {
    'Coffee Beans': Ingredient(name: 'Coffee Beans', stock: 1000, unit: 'g', purchasePrice: 0.010, totalCost: 10.0),
    'Milk': Ingredient(name: 'Milk', stock: 2000, unit: 'ml', purchasePrice: 0.002, totalCost: 4.0),
    'Sugar': Ingredient(name: 'Sugar', stock: 500, unit: 'g', purchasePrice: 0.003, totalCost: 1.5),
    'Water': Ingredient(name: 'Water', stock: 5000, unit: 'ml', purchasePrice: 0.0001, totalCost: 0.5),
    'Croissant Dough': Ingredient(name: 'Croissant Dough', stock: 20, unit: 'pcs', purchasePrice: 0.150, totalCost: 3.0),
  };

  final List<Product> _products = [
    Product(
      name: 'Espresso',
      price: 1.2,
      category: 'Beverage',
      recipe: [
        RecipeItem(ingredientName: 'Coffee Beans', amount: 18),
        RecipeItem(ingredientName: 'Water', amount: 30),
      ],
    ),
    Product(
      name: 'Latte',
      price: 2.5,
      category: 'Beverage',
      recipe: [
        RecipeItem(ingredientName: 'Coffee Beans', amount: 18),
        RecipeItem(ingredientName: 'Milk', amount: 200),
        RecipeItem(ingredientName: 'Water', amount: 30),
      ],
    ),
  ];

  final List<CartItem> _cart = [];
  final List<SaleRecord> _sales = [];
  final List<ExpenseRecord> _expenses = [];
  String _searchQuery = "";

  void _addToCart(Product product) {
    if (product.canMake(_inventory)) {
      setState(() {
        for (var item in product.recipe) {
          _inventory[item.ingredientName]!.stock -= item.amount;
        }
        final existingIndex = _cart.indexWhere((item) => item.product.name == product.name);
        if (existingIndex >= 0) {
          _cart[existingIndex].quantity++;
        } else {
          _cart.add(CartItem(product: product));
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient ingredients for ${product.name}!')),
      );
    }
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      for (var recipeItem in item.product.recipe) {
        _inventory[recipeItem.ingredientName]!.stock += recipeItem.amount;
      }
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cart.remove(item);
      }
    });
  }

  double get _total => _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  void _checkout() {
    setState(() {
      _sales.add(SaleRecord(
        date: DateTime.now(),
        items: List.from(_cart),
        total: _total,
      ));
      _cart.clear();
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sale Complete'),
        content: const Text('Inventory has been updated based on the recipe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showInventoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ingredient Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.blueGrey), onPressed: _addNewIngredientDialog),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _inventory.values.map((ing) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Avg cost: OMR ${ing.purchasePrice.toStringAsFixed(3)}/${ing.unit}\n'
                      'Total value: OMR ${ing.totalCost.toStringAsFixed(2)}'
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${ing.stock.toStringAsFixed(1)} ${ing.unit}', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: ing.stock < 100 ? Colors.red : Colors.black)),
                        Text('Long press to restock', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    onLongPress: () => _restockIngredient(ing),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewIngredientDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    final totalCostController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Raw Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock')),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (g, ml, pcs, etc.)')),
            TextField(
              controller: totalCostController, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(
                labelText: 'Total Bill Amount (OMR)',
                hintText: 'What was the total on the invoice?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final stock = double.tryParse(stockController.text) ?? 0;
                final totalCost = double.tryParse(totalCostController.text) ?? 0;
                final pricePerUnit = stock > 0 ? totalCost / stock : 0;
                setState(() {
                  _inventory[nameController.text] = Ingredient(
                    name: nameController.text,
                    stock: stock,
                    unit: unitController.text,
                    purchasePrice: pricePerUnit,
                    totalCost: totalCost,
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${nameController.text} added! Price per ${unitController.text}: OMR ${pricePerUnit.toStringAsFixed(3)}')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _restockIngredient(Ingredient ing) {
    final amountController = TextEditingController();
    final totalCostController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restock ${ing.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current stock: ${ing.stock.toStringAsFixed(1)} ${ing.unit}\n'
              'Current avg cost: OMR ${ing.purchasePrice.toStringAsFixed(3)} per ${ing.unit}\n'
              'Current total value: OMR ${ing.totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount to add (${ing.unit})'),
            ),
            TextField(
              controller: totalCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Bill Amount (OMR)',
                hintText: 'What was the total on the invoice?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              final totalCostOfBatch = double.tryParse(totalCostController.text);
              if (amount != null && amount > 0 && totalCostOfBatch != null && totalCostOfBatch > 0) {
                final pricePerUnitOfBatch = amount > 0 ? totalCostOfBatch / amount : 0;
                setState(() {
                  // Update stock
                  ing.stock += amount;
                  // Update total cost
                  ing.totalCost += totalCostOfBatch;
                  // Calculate new average price per unit
                  ing.purchasePrice = ing.totalCost / ing.stock;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added ${amount.toStringAsFixed(1)} ${ing.unit} for OMR ${totalCostOfBatch.toStringAsFixed(2)}.\n'
                      'New avg cost: OMR ${ing.purchasePrice.toStringAsFixed(3)} per ${ing.unit}'
                    ),
                  ),
                );
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (OMR)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _products.add(Product(
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    category: 'General',
                    recipe: [],
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRecipeEditor(Product product) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Recipe: ${product.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Link ingredients to this product:'),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: product.recipe.length,
                    itemBuilder: (context, i) {
                      final item = product.recipe[i];
                      return Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButton<String>(
                              value: item.ingredientName,
                              isExpanded: true,
                              items: _inventory.keys.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => item.ingredientName = val);
                                  setDialogState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(suffixText: _inventory[item.ingredientName]?.unit ?? ''),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setState(() => item.amount = double.tryParse(val) ?? 0);
                              },
                              controller: TextEditingController(text: item.amount.toString()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() => product.recipe.removeAt(i));
                              setDialogState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (_inventory.isNotEmpty) {
                      setState(() => product.recipe.add(RecipeItem(ingredientName: _inventory.keys.first, amount: 0)));
                      setDialogState(() {});
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ingredient Link'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    final descController = TextEditingController();
    final amtController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: amtController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(amtController.text);
              if (amt != null && descController.text.isNotEmpty) {
                setState(() {
                  _expenses.add(ExpenseRecord(
                    description: descController.text,
                    amount: amt,
                    date: DateTime.now(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showReports() {
    final totalSales = _sales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalExpenses = _expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _reportTile('Total Revenue', totalSales, Colors.green),
            _reportTile('Total Expenses', totalExpenses, Colors.red),
            const Divider(),
            const Text('Sales History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _sales.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text('Sale #${i + 1}'),
                  subtitle: Text(_sales[i].date.toString().substring(0, 16)),
                  trailing: Text('OMR ${_sales[i].total.toStringAsFixed(2)}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(String title, double value, Color color) {
    return ListTile(
      title: Text(title),
      trailing: Text('OMR ${value.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bisa POS', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(icon: const Icon(Icons.add_box, color: Colors.white), tooltip: 'Add Product', onPressed: _showAddProductDialog),
          IconButton(icon: const Icon(Icons.money_off, color: Colors.white), tooltip: 'Add Expense', onPressed: _showAddExpenseDialog),
          IconButton(icon: const Icon(Icons.inventory, color: Colors.white), tooltip: 'Inventory', onPressed: _showInventoryDialog),
          IconButton(icon: const Icon(Icons.bar_chart, color: Colors.white), tooltip: 'Reports', onPressed: _showReports),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      bool available = product.canMake(_inventory);
                      return Card(
                        color: available ? Colors.white : Colors.grey[200],
                        child: ListTile(
                          onLongPress: () => _showRecipeEditor(product),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('OMR ${product.price} (Hold to edit recipe)'),
                          trailing: ElevatedButton(
                            onPressed: available ? () => _addToCart(product) : null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                            child: const Text('Add', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(_cart[i].product.name),
                        subtitle: Text('x${_cart[i].quantity}'),
                        onTap: () => _removeFromCart(_cart[i]),
                      ),
                    ),
                  ),
                  const Divider(),
                  Text('Total: OMR ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _checkout,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
                      child: const Text('CHECKOUT', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
