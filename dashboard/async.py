import asyncio


async def my_async_function():
  await asyncio.sleep(1)
  print("Hello, world!")
  return "Done!"

async def main():
  done = await my_async_function()

asyncio.run(main())
