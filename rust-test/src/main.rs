mod module;

fn main() {
    println!("Hello, world!");
    let sq = module::Square(12, 12);
    module::test(sq);
}
