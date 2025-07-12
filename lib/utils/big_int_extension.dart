extension BigIntExtensions on BigInt {
  int toInt() => this > BigInt.from(0) ? this.toInt() : 0;
  DateTime toDateTime() => DateTime.fromMillisecondsSinceEpoch(this.toInt() * 1000);
}
