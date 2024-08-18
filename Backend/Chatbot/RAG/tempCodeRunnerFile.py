        # Define column widths
        col_widths = {
            "record_no": 10,
            "category_name": 20,
            "amount": 10,
            "emoji": 5,
            "deadline": 15,
            "reminder": 20
        }

        # Print header with proper alignment
        header_format = f"{{:<{col_widths['record_no']}}}{{:<{col_widths['category_name']}}}{{:<{col_widths['amount']}}}{{:<{col_widths['emoji']}}}{{:<{col_widths['deadline']}}}{{:<{col_widths['reminder']}}}"
        print(header_format.format("record no.", "category_name", "amount", "emoji", "deadline", "reminder"))

        # Print each row with proper alignment
        for i, row in enumerate(results, start=1):
            print(header_format.format(
                i,
                row['category_name'],
                row['amount'],
                row['emoji'],
                row['deadline'],
                row['reminder']
            ))