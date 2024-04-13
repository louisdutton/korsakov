// Example JavaScript file to test generic language support
function greet(name) {
    const message = `Hello, ${name}!`;
    console.log(message);
    return message;
}

class Calculator {
    constructor() {
        this.result = 0;
    }
    
    add(x, y) {
        this.result = x + y;
        return this.result;
    }
}

const calc = new Calculator();
calc.add(5, 3);
greet("World");